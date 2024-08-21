# Tutorial 0 - Overview

## Abstract

_Zero Trust principles represent a departure for how systems traditionally communicate with each other. Instead of long-lived credentials, access is granted based on caller identity to enable elevated security controls. Most public cloud providers and hosted solutions support assigning identities to workloads and has been enabled in many applications and frameworks. However, many end users are unaware of the baseline fundamental concepts. In this interactive tutorial, attendees will dive into the world of workload identity management, their components, how identities are generated, and where they can be used. By leveraging SPIFFE and SPIRE, CNCF projects providing tools for establishing trust between systems, we'll showcase how workload identities can be used beyond the Public Cloud to secure applications and systems in any environment. Upon completion, participants will have the knowledge, skills, and real world examples to implement these patterns in their own environments._

## Tutorial Overview and Introduction

Applications interact with a variety of resources to fulfill their business objectives. In order to facilitate the communication between components in a secure fashion, one of the common mechanisms that is used to facilitate this secure communication is for the caller to provide credentials in order for gaining access to the desired set of resources. By providing their credentials, they are enabling the target system to verify and grant access to the caller as needed. 

One of the primary challenges when when working with system requiring that authentication be performed is that long lived, or static, credentials is used to act as the means of providing an identity. The use of long lived credentials presents several challenges including:

* Misconfiguration of policies to enable elevated level of access
* Extended opportunity to exploit credentials
* If an attacker gains access to the credential, they will have access to resources, potentially without the knowledge of the resource owner.

### Workload Identity as a solution to long lived credentials

In order to avoid the use of long lived credentials when communicating between different systems, a popular approach that is used today is to leverage the concept of Workload Identity by which assigns an identity to a resource (such as an application) which is used to authenticate or access remote resource. Most public cloud providers, including Amazon Web Services (AWS), Google Cloud, and Microsoft Azure implement some form of workload identity. While this provides a solution when operating in these environment, it does present challenges when working outside of these environments, including on premise, and non cloud based environments.

[SPIFFE](https://spiffe.io), the Secure Production Identity Framework for Everyone, is a set of open-source standards designed to provide identities for services across various infrastructures, both public and private. It uses short-lived cryptographic identity documents, known as SVIDs (SPIFFE Verifiable Identity Documents), allowing workloads to authenticate to each other securely. For more detailed information on the SPIFFE ecosystem and its applications, visit the [project website](https://spiffe.io/).

[SPIRE](https://github.com/spiffe/spire) (the SPIFFE Runtime Environment) is an implementation of SPIFFE that offers a comprehensive toolchain for identity management and attestation. It verifies running software, issues and rotates identity tokens, and serves as a central point of federation with [OIDC](https://openid.net/developers/how-connect-works/) (OpenID Connect) discovery. SPIRE is designed to be production-ready and highly scalable, with a wide range of adopters. For an extensive list of current adopters, check out the [ADOPTERS.md](https://github.com/spiffe/spire/blob/main/ADOPTERS.md) file. To learn more or to try SPIRE, visit the [SPIFFE documentation](https://spiffe.io/docs/latest/try/)

### Workload Identity in Action

In order to illustrate some of the challenges that are found with the ways that systems typically communicate with each other using long lived credentials, the following set of tutorials will introduce a typical scenario that plays out within organizations throughout the world during the development and operational phase of applications, and the steps that can be taken to secure them.

Let's introduce two personas who will help on this journey.

* **Bob is a developer** looking to create a new Python application that access resources within a backend database. His initial implementation makes use of static credentials to interact with resources stored in the database so that he can quickly show the business value of his work and get feedback.

* **Kaya, a savvy platform administrator** hears about the successes of Bob's demonstration to the business, but is concerned with the security of the application. Aside from performing common platform related tasks, she also has an ear on the latest trends and approaches to securing infrastructure and application. 

Kaya suggests that Bob strengthen the overall posture of his application by introducing workload identify, and specifically the SPIFFE and SPIRE ecosystem, to eliminate the use of long lived credentials when accessing protected resources. By implementing secure practices within the design and implementation of the his application, Bob will be able learn the benefits that are provided by the use of workload identify so that the pattern and technologies can be adopted by additional applications and systems throughout the organization.

Let's take this journey together throughout the following tutorial exercises to be able to achieve a more secure future!

## Environment Details

This tutorial makes use of a [Kubernetes](https://kubernetes.io) environment. For the live demo, we have made available One Node [OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) clusters for each participant to access and work through the various exercises. This tutorial is not dependent on OpenShift. We have now made available the instructions to set up a [Kind](https://kind.sigs.k8s.io/) cluster and demonstrate how workload identity can be achieved. 

While Kubernetes is being used from an implementation perspective, the solutions here are not dependent on Kubernetes. 

Each participant will have access to a cluster of their own to work though the various exercises of this tutorial. Additional information including how to gain access to the environment can be found in the next section, Accessing the environment.

For the live demo, additional information about accessing and interacting with the environment can be found in the first link below. To run the demo locally on Kind, the instructions for setting up the environment are in the second link below

[Next Tutorial - Environment Access for Live Tutorial](tutorial1a.md)

[Next Tutorial - Environment Setup on Kind](tutorial1b.md)

[Home](../README.md)
