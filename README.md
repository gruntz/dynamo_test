# Simple devops project for Dynamo

/
├── DynamoApp  - The frontend, backend and piplelines;
├── terraform  - Terraform scripts to bring the env up;
└── READEME.md - This file

1) Terraform is used to bring two VMs ( Server and Worker) up. It also installs DotNet and IIS web server.

2) DynamoApp is a simple app that returns Hello Dynamo.
* It uses DotEnd backend, that listens on port 5000 for connections and responds.
* Index.html is the front end. There is a button, that makes the request to the backend and prints the response.
* azure-pipelines-build is the pipeline that builds the app on the Worker and prepares the artifacts.
* azure-pipelines-deploy is the pipeline that pushes the frontend and backend to the Server and starts listening on port 5000

3) Both machines have Azure DevOps agents. One is used for the build, and the other for the release.
4) Server is set as "Environment" so the app will be deployed to that environment. 