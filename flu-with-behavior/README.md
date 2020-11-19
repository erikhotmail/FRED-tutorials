# Flu with Behaviour Model

## Introduction

This model builds on the Simple Flu model (see `../simpleflu`) by equipping agents with rudimentary social distancing behaviour. In the Simple Flu model, agents with the flu continue to behave in the same way as agents without the flu, and will continue to visit all the places they usually visit including work and school. In the Flu with Behaviour Model, agents who become infected with the flu and are symptomatic have a 50% chance of deciding to stay at home for the duration of time it takes them to recover.

## Review of code implementing the model

The Flu with Behaviour Model is comprised of three files:

- `main.fred`
- `simpleflu.fred`
- `stayhome.fred`

Here we review the code in these files, focusing on how features of the FRED language are used to implement the Flu with Behaviour Model described above.

### `main.fred`

Like most FRED models, entry point to the Flu wit Model Behaviour models is a file called `main.fred`. This file specifies the basic simulation control parameters and coordinates how relevant sub-models are loaded. The `simulation` code block from `main.fred` is given below

```fred
simulation {
    locations = Jefferson_County_PA 
    start_date = 2020-Jan-01
    end_date = 2020-May-01
    weekly_data = 1
}
```

This is the same as the `simulation` code block from the Simple Flu model. It specifies that the model represents the simulated population for Jefferson County, PA for the period January 1 2020 to May 1 2020.

TODO: Explain the effect of including `weekly_data = 1`.

The remaining lines in `main.fred` demonstrate the use of [`include` statements](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter4/chapter4.html#include-statements) to import sub-models.

```fred
include simpleflu.fred
include stayhome.fred
```

The use of separate files to contain sub-models helps to keep code organised, improves readability and promotes code reuse. Importantly the order in which the sub-model files are specified here determines the order in which they will be processed by the compiler. This is important because FRED defines rules for how property definition statements and state update rule statements are overridden or updated by subsequent statements relating to the same property or state. 

TODO: Discuss state update rules in more detail. In [The Structure of a FRED Program](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter4/chapter4.html#the-structure-of-a-fred-program) we are told that "Property definition statements occurring later in the program override any previous definitions for the same property." However I have not yet found where the rules for later redefinitions of state rules is specified in the user guide.

### `simpleflu.fred`

`simpleflu.fred` is identical to the file of the same name in the Simple Flu model. It specifies the state update rules for the `INF` Condition that models agents' status with respect to influenze infection. Refer to the tutorial on the Simple Flu Model for a complete explanation of the code in `simpleflu.fred`. For the purpose of this tutorial, consider the following snippet which specifies the State rules for the `Is` (infected and symptomatic) state belonging to the `INF` condition:

```fred
    state Is {
        INF.trans = 1
        wait(24* lognormal(5.0,1.5))
        next(R)
    }
```

TODO: add rule for `INF.R`

Here `INF.trans = 1` is an action rule that causes an agent entering the `INF.Is` state to change its [transmissibility](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter9/chapter9.html#the-transmissibility-of-an-agent) of influenza to `1`. The wait rule `wait(24* lognormal(5.0,1.5))` causes each agent that becomes infectious and symptomatic to remain so for a number of days determined by sampling from a [lognormal distribution](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter5/chapter5.html?highlight=lognormal#statistical-distributions) with median=5.0 and dispersion=1.5. Finally the transition rule `next(R)` causes agents to transition, deterministically, to the `R` (recovered) state once their period of infection has elapsed.

### `stayhome.fred`

This file contains the code that implements the social distancing sub-model that is particular to the Flu with Behaviour Model. We first specify a new Condition, `StayHome`

```fred
condition StayHome {

    state No {}

    state Yes {
        absent()
        present(Household)
        wait()
        next()
    }
}
```

The empty braces following the declaration of the `No` state causes it to be assigned the [default configuration](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html#chapter-7-rules-for-states)--agents entering this state perform no actions and remain in this state indefinitely unless influenced by an external factor, including an action of a state belonging to a different Condition. The configuration of the `Yes` state demonstrates a feature of the FRED language which has not been demonstrated previosuly: the `absent` and `present` actions. If an agent is **absent** from a group or location, they do not attend that group even if they otherwise would. The statement `absent()` causes an agent to avoid _all_ groups or locations. Conversely `present(Household)` causes agents who were previously absent from their household to go there. The combination of the `absent()` and `present(Household)` actions in the definition of the `StayHome.Yes` state cause agents to _only_ attend their household. Finally the `wait()` and `next()` wait and transition rules cause agents to remain in this state indefinitely.

The remaining code blocks in `stayhome.fred` specify how agents decide to stay at home or not depending on their status with respect to the `INF` (i.e. influenza) condition.

```fred
state INF.Is {
    if (bernoulli(0.5) == 1) then set_state(StayHome,Yes)
}
```

As `stayhome.fred` is imported into `main.fred` after `simpleflu.fred` the interpreter appends these statements to the end of the statements in the `INF.Is` declaration in `simpleflu.fred`, and then interprets them [with the order](https://epistemix-fred-guide.readthedocs-hosted.com/en/latest/user_guide/chapter7/chapter7.html?highlight=absent#order-of-rule-execution-in-a-state):

1. Action Rules
2. Wait Rules
3. Transition Rules

Consequently the above code block in combination with the relevant statements in `simpleflu.fred` results in an effective definition of the `INF.Is` state for the simulation overall as

```fred
state Is {
    INF.trans = 1
    if (bernoulli(0.5) == 1) then set_state(StayHome,Yes)
    wait(24* lognormal(5.0,1.5))
    next(R)
}
```

set_state is an action rule, which means it's executed when the agent enters the state

This is an example of modifying the `INF.Is` state that is assumed to have been previously defined in the program. In the case of this example, it is provided in the `simpleflu.fred` file that is included before `stayhome.fred` in `main.fred`.

Once a state has been defined within a condition, any statements in blocks corresponding to that state specified later in the programme are _appended_ to the rules spcified previously, rather than replacing them. This feature is utilised in the 

## Sample model outputs

### Running the model

Open a terminal and navigate to the directory where the Flu with Behaviour model is saved, for example:

```bash
cd ~/models/flu-with-behaviour
```

We can use the `METHODS` script provided with the model files to run the model and generate some visualisations of its outputs:

```bash
./METHODS
```

#### TODO

- Include images of model outputs
- Run simulated experiments suggested in TODO.txt

## Summary

### New language features used

In addition to the features of the FRED language used in the Simple Flu model, this model also demonstrates the following features:

- The `absent` and `present` actions are used in `stayhome.fred` to control the Places agents attend, depending on their conditions.
- State rule shadowing is used in `stayhome.fred` to modify the the rules for a state defined previously in the program.

### Illustrative scientific/ policy findings from model runs

#### TODO
