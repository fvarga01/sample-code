import yaml
from jinja2 import Environment, FileSystemLoader

# Load variables from the YAML file
with open('variables.yaml', 'r') as file:
    config = yaml.safe_load(file)

# Set up the Jinja2 environment
env = Environment(loader=FileSystemLoader('.'))
template = env.get_template('variables.tf.j2')

# Render the template with the variables loaded from YAML
output = template.render(variables=config['variables'])

# Write the output to a file
with open('variables.tf', 'w') as f:
    f.write(output)

print("Terraform variables.tf file has been generated.")