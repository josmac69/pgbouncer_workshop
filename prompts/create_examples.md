All rules in this prompt are mandatory and you must follow them strictly.
Find PDF file and latex slides in ./pgbouncer folder.
Both describe how to run multiple PgBouncer instances with systemd on a single server.
Your task is to create runnable example based on the content of these files.
Create example in the directory ./pgbouncer/multiple_instances_example.
Solution must run in a docker container.
Create docker-compose.yml file that sets up the environment and Makefile that runs the example.
All configuration files must be placed in ./pgbouncer/multiple_instances_example/config folder and must be mapped to the container in the docker-compose.yml file.
