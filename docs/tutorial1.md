# Tutorial 1 - Environment Access

For the purpose of this tutorial, each participant will make use of an Kubernetes based OpenShift environment to work through the exercises. Access to environments, including the endpoints and credentials  will be provided by the instructors.

## Exploring the Environment

Once details relating to the environment has been provided, the next step is accessing the target OpenShift environment. Two methods can be used to interact with an OpenShift environment:

* OpenShift Web Console
* Command Line Interface (CLI)

The OpenShift CLI tool (`oc`) is a superset of the features provided by the Kubernetes CLI (`kubectl`) and provides capabilities tailored for OpenShift environments. However, none of the material contained within this tutorial make use of the OpenShift specific features.

However, instead of using either of the CLI options, all actions will be performed using the OpenShift Web Console and the included tooling.

### Interacting With the Environment

Navigate to the OpenShift Web Console using the URL associated with your environment. Enter the username and password on the login page using the credentials provided. Once authenticated, you will be presented with the OpenShift Dashboard. Feel free to browse around to become familiar with the options available as they may be helpful when working through the exercises.

The [Web Terminal](https://docs.openshift.com/container-platform/4.15/web_console/web_terminal/odc-using-web-terminal.html) is a capability found embedded within the OpenShift Web Console and includes tools, such as `kubectl`, `helm`, `jq`, to assist when working with the platform. It also simplifies how to work through the exercises as no additional set up or configuration is needed on end user workstations.

The Web Terminal can be accessed from the OpenShift Web Console by clicking on the Terminal icon on the masthead of the console, next to the username. 

**TODO: Insert Picture of the Terminal Icon**

Click on the Terminal icon to launch a session which will open a pane at the bottom of the screen

**TODO: Insert Picture of Web Terminal**

Proceed to the next tutorial where the application, including its architecture, will be introduced and deployed to the environment using traditional methods of authentication with long lived credentials. 

[Previous Tutorial - Overview](tutorial0.md)

[Next Tutorial - Application Deployment](tutorial2.md)

[Home](../README.md)