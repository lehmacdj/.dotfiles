#!/usr/bin/env python3
# Finds unnecessary homebrew formulas defined by those that aren't a dependency
# of the output of brew leaves

import subprocess

def find_unnecessary_formulas(dependency_info, formula_list):
    installed_formulas = set()

    # Parse the input text to extract installed formulas and their dependencies
    lines = dependency_info.split('\n')
    for line in lines:
        if ':' in line:
            parts = line.split(':')
            formula = parts[0].strip()
            dependencies = [dep.strip() for dep in parts[1].split()]
            installed_formulas.add(formula)
            installed_formulas.update(dependencies)

    # Find unnecessary formulas
    unnecessary_formulas = set(formula_list) - installed_formulas

    return unnecessary_formulas

# Generate dependency_info from the output of `brew deps --for-each $(brew leaves)`
leaves = subprocess.run(["brew", "leaves"], capture_output=True, text=True)
leaves_list = leaves.stdout.strip().split('\n')
result = subprocess.run(["brew", "deps", "--for-each"] + leaves_list, capture_output=True, text=True)
dependency_info = result.stdout.strip()

# Generate formula_list from `brew list --formula -1`
result = subprocess.run(["brew", "list", "--formula", "-1"], capture_output=True, text=True)
formula_list = result.stdout.strip().split('\n')

# Find and print unnecessary formulas
unnecessary_formulas = find_unnecessary_formulas(dependency_info, formula_list)
print("Unnecessary Formulas:")
for formula in unnecessary_formulas:
    print(formula)
