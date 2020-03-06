---
title: "{{ replace .Name "-" " " | title }}"
{{ if .Site.Author.name -}}
authors: "{{ .Site.Author.name }}"
{{- end }}
date: {{ .Date }}
subtitle: ""
image: ""
tags: []
draft: true
---
