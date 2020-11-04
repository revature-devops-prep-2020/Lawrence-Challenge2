#!/bin/sh
namespace="challenge2"
token_name=$(kubectl -n $namespace get serviceaccount kubectl-agent -o go-template --template='{{range .secrets}}{{.name}}{{"\n"}}{{end}}')
kubectl -n $namespace get secrets $token_name -o go-template --template '{{index .data "token"}}' | base64 -d