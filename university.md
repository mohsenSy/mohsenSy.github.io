---
layout: default
title: university
permalink: /university/
---

In this page I will upload all my lectures taught at Information Engineering Faculty in Tishreen university.

{% for course in site.courses %}
  <a href="{{ course.url }}">{{ course.name }}</a>
{% endfor %}
<br />
<a href="{{ site.url }}/university/project_ideas"> Project Ideas</a>
