#! /usr/bin/env bash

PROB_STAY_HOMES='0.1 0.3 0.5 0.7'

for P in $PROB_STAY_HOMES
do
    # Generate parameters.fred file
    printf "parameters {\n    ProbSympStayHome = ${P}\n}\n" > parameters.fred

    # Determine the job name for the run with this parameter
    KEY="stay-home-prob=${P}"
    # Add job name to an accumulating list of job names
    KEY_LIST="${KEY_LIST},${KEY}"
    # Add parameter to an accumulating list of parameters
    PARAM_LIST="${PARAM_LIST},ProbSympStayHome=${P},"

    # Clear any existing results with this key
    fred_delete -f -k $KEY

    # Run the simulation
    fred_job -k $KEY -p main.fred -n 4 -m 2
done

# Plot the results
fred_plot -o prob-stay-home -k $KEY_LIST \
    -v INFLUENZA.newExposed,INFLUENZA.newExposed \
    -t "Probability of staying home parameter sweep" \
    -l $PARAM_LIST
