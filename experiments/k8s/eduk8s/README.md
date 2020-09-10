# Installing edukates

This collection of scripts and custom Kubernetes API resources are responsible for making it dead simple to install and manage [edukates](https://docs.edukates.io/en/latest/project-details/project-overview.html).

The edukates project is designed to provide a platform for hosting workshops. It was primarily created to support the work of a team of developer advocates who needed to train users in using Kubernetes and show case developer tools or applications running on Kubernetes.

Although edukates requires Kubernetes to run, and is being used to teach users about Kubernetes, it could also be used to host training for other purposes as well. It may for example be used to help train users in web based applications, use of databases, or programming languages, where the user has no interest or need for Kubernetes.

Assumes:

* You have a cluster and cluster admin credentials
* You have pre-installed nginx-ingress-controller, cert-manager, and external-dns

## Install

```
./create-eduk8s.sh {release-version} {domain}
```
> Replace `{release-version}` above with one of the available [release versions](https://github.com/eduk8s/eduk8s/releases) of the `eduk8s-operator`.  If you want to deploy the very latest and greatest use `master`. 

## Load Workshops

```
./load-workshops.sh
```

## List Workshops

```
./list-workshops.sh
```

## Remove

```
./destroy-eduk8s.sh {release-version}
```