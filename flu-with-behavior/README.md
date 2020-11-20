# Flu with Behavior Model

## Introduction

This model builds on the Simple Flu model (see `../simpleflu`) by equipping agents with rudimentary social distancing behavior. In the Simple Flu model, agents with the flu continue to behave in the same way as agents without the flu, and will continue to visit all the places they usually visit including work and school. In the Flu with Behavior Model, agents who become infected with the flu and are symptomatic have a 50% chance of deciding to stay at home for the duration of time it takes them to recover.

## Review of code implementing the model

The code that implements the Flu with Behavior Model is contained in three `.fred` files:

- `main.fred`
- `simpleflu.fred`
- `stayhome.fred`

Here we review the code in these files, focusing on how features of the FRED language are used to implement the Flu with Behavior Model described above.

### `main.fred`

Like most FRED models, the entry point to the Flu with Behavior Model is a file called `main.fred`. This file specifies the basic simulation control parameters and coordinates how relevant sub-models are loaded. The `simulation` code block from `main.fred` is given below

```fred
simulation {
    locations = Jefferson_County_PA
    start_date = 2020-Jan-01
    end_date = 2020-May-01
    weekly_data = 1
}
```

This is the same as the `simulation` code block from the Simple Flu model. It specifies that the model will be used to simulate the behavior of the synthetic population for Jefferson County, PA for the period January 1 2020 to May 1 2020. By default FRED produces simulation outputs quantifying the evolution of the number of agents in each state on a daily basis in the directory `$FRED_HOME/RESULTS/JOB/<job_num>/OUT/<run_num>/DAILY`. Here `job_num` and `run_num` are, respectively, the job and run numbers for the simulations and are determined at runtime. If `weekly_data = 1` is specified, additional datasets are generated in `$FRED_HOME/RESULTS/JOB/<job_num>/OUT/<run_num>/WEEKLY` that correspond to the daily datasets, but aggregated to the [CDC epidemiological ('epi') week](https://wwwn.cdc.gov/nndss/document/MMWR_Week_overview.pdf) level.

The remaining lines in `main.fred` demonstrate the use of [`include` statements](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter4/chapter4.html#include-statements) to import sub-models.

```fred
include simpleflu.fred
include stayhome.fred
```

The use of separate files to contain sub-models helps to keep code organized, improves readability and promotes code reuse. Importantly the order that the sub-model files are specified here determines the order in which they will be processed by the compiler. This is important because FRED defines rules for how property definition statements and state update rule statements are overridden or updated by subsequent statements relating to the same property or state.

#### TODO: Discuss state update rules in more detail

In [The Structure of a FRED Program](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter4/chapter4.html#the-structure-of-a-fred-program) we are told that "Property definition statements occurring later in the program override any previous definitions for the same property." However I have not yet found where the rules for later redefinitions of state rules is specified in the user guide.

Once a state has been defined within a condition, any statements in blocks corresponding to that state specified later in the programme are _appended_ to the rules specified previously, rather than replacing them.

Propose we refer to this as 'state rule shadowing'

### `simpleflu.fred`

`simpleflu.fred` is identical to the file of the same name in the Simple Flu model. It specifies the state update rules for the `INFLUENZA` Condition that models agents' status with respect to influenza infection. Specifically, each agent is in one of the following five states:

1. Susceptible to infection with influenza
2. Exposed to influenza
3. Infectious and symptomatic with influenza
4. Infectious and asymptomatic with influenza
5. Recovered following infection with influenza and assumed to be immune

Refer to the tutorial on the Simple Flu Model for a complete explanation of the code in `simpleflu.fred`. For the purpose of this tutorial, consider the following code snippet which specifies the State rules for the `InfectiousSymptomatic` and `Recovered` States belonging to the `INFLUENZA` condition:

```fred
    state InfectiousSymptomatic {
        INFLUENZA.trans = 1
        wait(24* lognormal(5.0,1.5))
        next(Recovered)
    }

    ...

    state Recovered {
        INFLUENZA.trans = 0
        wait()
        next()
    }
```

Here `INFLUENZA.trans = 1` and `INFLUENZA.trans = 0` are action rules that cause agents entering the `INFLUENZA.InfectiousSymptomatic` state to change their [transmissibility](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter9/chapter9.html#the-transmissibility-of-an-agent) of influenza to 1, and agents entering the `INFLUENZA.Recovered` state to change their transmissibility of influenza to 0 (i.e. they are non-infectious). The wait rule `wait(24* lognormal(5.0,1.5))` causes each agent that becomes infectious and symptomatic to remain so for a number of days determined by sampling from a [lognormal distribution](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter5/chapter5.html?highlight=lognormal#statistical-distributions) with median=5.0 and dispersion=1.5. Finally the transition rule `next(Recovered)` causes agents to transition, deterministically, to the `Recovered` state once their period of infection has elapsed. The wait rule `wait()` and transition rule `next()` cause agents that enter the `Recovered` state to remain in that state indefinitely.

### `stayhome.fred`

This file contains the code that implements the social distancing sub-model that is particular to the Flu with Behavior Model. We first specify a new Condition, `STAY_HOME`

```fred
condition STAY_HOME {

    state No {}

    state Yes {
        absent()
        present(Household)
        wait()
        next()
    }
}
```

The empty braces following the declaration of the `No` state causes it to be assigned the [**default configuration**](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#chapter-7-rules-for-states)--agents entering this state perform no actions and remain in this state indefinitely unless influenced by an external factor (including an action rule of a state belonging to a different Condition). The configuration of the `Yes` state demonstrates a feature of the FRED language which has not been demonstrated previously: the [`absent` and `present` actions](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#actions-affecting-an-agent-s-groups). If an agent is **absent** from a group or location, they do not attend that group even if they otherwise would. The statement `absent()` causes an agent to avoid _all_ groups or locations. Conversely `present(Household)` causes agents who were previously absent from their household to resume attending their household. The combination of the `absent()` and `present(Household)` actions in the definition of the `STAY_HOME.Yes` state cause agents entering that state to _exclusively_ attend their household (i.e. stay home). Finally the `wait()` wait rule and `next()` transition rule cause agents to remain in the `Yes` state indefinitely.

The remaining code blocks in `stayhome.fred` specify how agents decide to stay at home or not depending on their state with respect to the `INFLUENZA` condition.

```fred
state INFLUENZA.InfectiousSymptomatic {
    if (bernoulli(0.5)==1) then set_state(STAY_HOME,Yes)
}


state INFLUENZA.Recovered {
    set_state(STAY_HOME,Yes,No)
}
```

Here `set_state` is [an action](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#actions-that-change-an-agent-s-state) that updates an agent's state. The statement `set_state(STAY_HOME,Yes,No)` in the `INFLUENZA.Recovered` code block causes agents entering the `INFLUENZA.Recovered` state whose `STAY_HOME` state is currently `Yes` to change their `STAY_HOME` state to `No`. The statement `if (bernoulli(0.5)==1) then set_state(STAY_HOME,Yes)` in the `INFLUENZA.InfectiousSymptomatic` code block is an example of a _conditional_ [action rule](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#action-rules). Any action rule can optionally include a conditional statement that causes the action to only be executed (on an agent-by-agent basis) if the associated predicate (or predicates) is true. In this case, each time an agent enters the `INFLUENZA.InfectiousSymptomatic` state, a Bernoulli trial with 0.5 probability of success is conducted (we might imagine the agent flips a coin). On a success, the agent changes its `STAY_HOME` state to `Yes`.

Because `stayhome.fred` is imported into `main.fred` after `simpleflu.fred`, the compiler appends the statements in the code blocks specified above to the end of the statements in the `INFLUENZA.InfectiousSymptomatic` and `INFLUENZA.Recovered` declarations in `simpleflu.fred`. It then interprets them _as if_ they had been declared according to [the following order](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#order-of-rule-execution-in-a-state):

1. Action Rules
2. Wait Rules
3. Transition Rules

Consequently the code blocks in the previous code snippet in combination with the relevant statements in `simpleflu.fred` result in the following effective definitions of the `INFLUENZA.InfectiousSymptomatic` and `INFLUENZA.Recovered` states for the simulation overall.

```fred
state InfectiousSymptomatic {
    INFLUENZA.trans = 1  # action rule
    if (bernoulli(0.5)==1) then set_state(STAY_HOME,Yes)  # action rule
    wait(24* lognormal(5.0,1.5))  # wait rule
    next(Recovered)  # transition rule
}


state Recovered {
    INFLUENZA.trans = 0  # action rule
    set_state(STAY_HOME,Yes,No)  # action rule
    wait()  # wait rule
    next()  # transition rule
}
```

This is an example of modifying the state rules of a state that is assumed to have been previously defined in the program.

## Sample model outputs

### Running the model

Open a terminal and navigate to the directory where the Flu with Behavior model is saved, for example:

```bash
cd ~/models/flu-with-behavior
```

We can use the `METHODS` script provided with the model files to run the model and generate some visualizations of its outputs:

```bash
./METHODS
```

#### TODO

- Include images of model outputs
- Run simulated experiments suggested in TODO.txt

## Summary

### Additional language features introduced

In addition to the features of the FRED language used in the Simple Flu model, this model also demonstrates the following features:

- The `absent` and `present` actions are used in `stayhome.fred` to control the Places agents attend, depending on their conditions.
- State rule shadowing is used in `stayhome.fred` to modify the the rules for a state defined previously in the program.
- `stayhome.fred` contains an example of a conditional action rule that is only executed if a predicate is true.

### Illustrative scientific/ policy findings from model runs

#### TODO
