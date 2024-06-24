# Tutorial 0 - Overview

## Abstract

_Zero Trust principles represent a departure for how systems traditionally communicate with each other. Instead of long-lived credentials, access is granted based on caller identity to enable elevated security controls. Most public cloud providers and hosted solutions support assigning identities to workloads and has been enabled in many applications and frameworks. However, many end users are unaware of the baseline fundamental concepts. In this interactive tutorial, attendees will dive into the world of workload identity management, their components, how identities are generated, and where they can be used. By leveraging SPIFFE and SPIRE, CNCF projects providing tools for establishing trust between systems, we'll showcase how workload identities can be used beyond the Public Cloud to secure applications and systems in any environment. Upon completion, participants will have the knowledge, skills, and real world examples to implement these patterns in their own environments._

## Tutorial Overview and Introduction

Applications interact with a variety of resources to fulfill their business objectives. In order to facilitate the communication between components in a secure fashion, one of the common mechanisms that is used to facilitate this secure communication is for the caller to provide credentials in order for gaining access to the desired set of resources. By providing their credentials, they are enabling the target system to verify and grant access to the caller as needed. 

One of the primary challenges when when working with system requiring that authentication be performed is that long lived, or static, credentials is used to act as the means of providing an identity. The use of long lived credentials presents several challenges including:

* Misconfiguration of policies to enable elevated level of access
* Extended opportunity to exploit credentials
* If an attacker gains access to the credential, they will have access to resources, potentially without the knowledge of the resource owner

### Workload Identity as a solution to long lived credentials

In order to avoid the use of long lived credentials when communicating between different systems, a popular approach that is used today is to leverage the concept of Workload Identity by which assigns an identity to a resource (such as an application) which is used to authenticate or access remote resource. Most public cloud providers, including Amazon Web Services (AWS), Google Cloud, and Microsoft Azure implement some form of workload identity. While this provides a solution when operating in these environment, it does present challenges when working outside of these environments, including on premise, and non cloud based environments.

[SPIFFE](https://spiffe.io), the Secure Production Identity Framework for Everyone, is a set of open-source standards for providing identities across infrastructures, including public and private environments. By leveraging short lived cryptographic identity documents, called SVID's, workloads can use these identity documents to authenticate to other workloads.

More information regarding the SPIFFE ecosystem and how it can be used in detail can be found on the [project website](https://spiffe.io).

### Workload Identity in Action

In order to illustrate some of the challenges that are found with the ways that systems typically communicate with each other using long lived credentials, the following set of tutorials will introduce a common two tier application architecture that exposes a frontend application that makes use of a database backend for sourcing material to perform the business requirements. Assets store within the database are protected which require that credentials be provided by any calling resource. 

The initial architecture will mirror how many applications are typically designed which make use of long lived credentials to communicate between different components. Once the solution has been deployed, and the challenges with long lived credentials are realized, additional measures will be introduced to not only harden the posture of the application architecture, but make use of workload identity (specifically SPIFFE) to eliminate the use of long lived credentials when accessing protected resources.

## Environment Details

This tutorial makes use of a [Kubernetes](https://kubernetes.io) environment, based on [OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift), to be able to demonstrate how workload identity can be achieved when working across cloud environments. While OpenShift and Kubernetes is being used from an implementation perspective, the concepts are not dependant solely on this type of architecture.

Each participant will have access to a cluster of their own to work though the various exercises of this tutorial. Additional information including how to gain access to the environment can be found in the next section, Accessing the environment.

[Next Tutorial - Environment Access](tutorial1.md)

[Home](../README.md)