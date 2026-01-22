All rules in this prompt are mandatory and you must follow them strictly.

Here I have description of pgbouncer use cases I want to implement as runnable examples in docker containers:

Name: Capping User Connections
Rules
- PgBouncer can limit connections per user/database pair
- Prevents a single user from exhausting all connections
- Parameters:
  - max_db_connections limits per database
  - max_user_connections limit per user
  - max_user_client_connections limit per user over all databases

Your task is to create runnable example based on this description.
Create example in the directory ./pgbouncer/capping_user_connections.
Solution must run in a docker container.
Create docker-compose.yml file that sets up the environment and Makefile that runs the example.
All configuration files must be placed in ./pgbouncer/capping_user_connections/config folder and must be mapped to the container in the docker-compose.yml file.