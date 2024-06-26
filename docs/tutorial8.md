# Tutorial 8 - Conclusion

This tutorial covered the introduction to Zero Trust principles in workload identity management, which enhances security by granting access based on caller identity rather than long-lived credentials. The focus was on using SPIFFE (Secure Production Identity Framework for Everyone) and SPIRE (SPIFFE Runtime Environment) to secure systems beyond public cloud environments, applicable to any infrastructure. Attendees gained knowledge and practical skills to implement these patterns.

We introduced the fundamental principles of Zero Trust and workload identity management, highlighting how these approaches enhance security by using caller identity instead of long-lived credentials.

To harden the architecture, we went through an exercise to decouple credentials from the application by removing the static credentials at rest within the cluster and storing them in a secret management solution, Vault, where they can be rotated dynamically and independently of the application.

This instance of Vault was configured to enable authentication using a JWT provided by SPIRE. Then, we granted policies for only specific identities, like our application, to have access to secrets.

By leveraging SPIFFE and SPIRE, we demonstrated how to secure an application by adding a simple sidecar that uses this application identity to access Vault, obtain dynamically managed credentials, and then inject them into the application.

We hope this tutorial provides you with a pattern example that can significantly harden the security posture of your deployed application.

## Links

### Resources and Relevant Technologies

* [SPIFFE Website](https://spiffe.io/)
* [SPIRE Github](https://github.com/spiffe/spire)
* [SPIRE Helm Charts](https://github.com/spiffe/helm-charts-hardened)
* [Kubernetes](https://kubernetes.io/)
* [OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift)
* [Hashicorp Vault](https://www.vaultproject.io/)
* [JSON Web Tokens](https://jwt.io/)

### Additional Relevant Resources for further exploration

* What about the Multicloud Usecase? -> Check out [SPIRE Federation](https://spiffe.io/docs/latest/spire-helm-charts-hardened-advanced/federation/)
* [Tornjak for SPIRE management](https://github.com/spiffe/tornjak/blob/dev/docs/user-management.md)
* What else can be used for SPIRE - app integration? -> Checkout [the SPIFFE Helper](https://github.com/spiffe/helm-charts-hardened/tree/main/examples/mysql-using-spire)
* [SPIRE + OIDC + Vault integration](https://spiffe.io/docs/latest/keyless/vault/readme/)

[Previous Tutorial - Securing the Python Application](tutorial7.md)

[Home](../README.md)