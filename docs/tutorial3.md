# Tutorial 3 - Identifying Security Challenges

Now that Kaya has Bob's application deployed, she begins to investigate the security concerns that are present within the application as it relates to the management of credentials used to communicate between the Python application and the backend database.

She quickly discovers that the connection details, including the username and password are being stored, at rest within the Kubernetes environment in a `ConfigMap` called `db-config`.

Execute the following command to view the contents of the `ConfigMap` to illustrate the severity of this configuration.

```shell
kubectl get cm -n workload-identity-tutorial db-config -o jsonpath='{ .data.config\.ini }'
```

The contents of the configuration file is shown below:

```ini
[mysql]
host=db
port=3306
db=testdb
user=root
passwd=testroot
```

Kaya knows that thanks to her organizations newly introduced security policies, the current architecture of Bob's Python application will not pass security compliance requirements.

Fortunately, she has ideas that will improve the overall design of the application. She schedules a meeting with Bob to propose her approach.  

## Hardening the Architecture

Bob is pleased to hear that Kaya has suggestions for hardening the application. They meet in a conference room where Kaya proposes several tenets for a more secure future of the application including:

1. Removing the use of storing static credentials at rest within the cluster
2. Introducing a tool for securely storing sensitive assets
2. Avoid obtaining access to sensitive assets using static credentials

While there are a number of tools that can be used to store sensitive assets, one such option that supports running in the public cloud as well as within self hosted environments is [HashiCorp Vault](https://www.vaultproject.io). Aside from managing the storage of sensitive resource, it also includes other capabilities, including data encryption, certificate management and identity based access.

The latter (identity based access) would enable achieving one of the other goals set forth for a more secure future application architecture as it avoids obtaining access to the sensitive assets using static credentials. So, instead of a fixed credential that can be used to gain access to Vault, information related to our workload running in Kubernetes can be used instead. Since there is a requirement for the solution to work in public clouds and in private environments, she selects SPIRE as the solution to provide identities to applications running on the cluster. By leveraging the ability to obtain a [JSON Web Token](https://jwt.io) (JWT), this resulting entity can be used to authenticate to Vault to gain access to resources. 

Kaya draws out her vision on the whiteboard to gauge Bob's thoughts on the future state architecture which includes:

1. Removing the `ConfigMap` containing the static credentials so that no sensitive assets is stored at reset
2. Deploying SPIRE to the cluster to provide identities to workloads
3. Deploying Vault to the cluster to store store sensitive assets and utilize identity based authentication to access stored content
4. Using workload identity to obtain resources stored in Vault when can then enable the Python application the ability to communicate with the backend database

With both Kaya and Bob in agreement on the future state design, they then set out to implement the approach in Kaya's Kubernetes cluster.

In the following sections of the tutorial, you will deploy and configure the additional components that are to be introduced into the cluster and then update the Python application to make use of these new tools to communicate with the backend database.

[Previous Tutorial - Application Deployment](tutorial2.md)

[Next Tutorial - Deploying SPIRE](tutorial4.md)

[Home](../README.md)
