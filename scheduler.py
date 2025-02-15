import yaml

# Define the environment details
env_data = {
    "name": "my_env",
    "channels": ["defaults", "conda-forge"],
    "dependencies": [
        "python=3.9",
        "numpy",
        "pandas",
        "scipy",
        {"pip": ["flask", "requests"]}
    ]
}

# Write to environment.yml
with open("environment.yml", "w") as file:
    yaml.dump(env_data, file, default_flow_style=False)

print("environment.yml file created successfully!")
