---
layout: default
c_name: Distributed  Applications
permalink: /university/distributed_applications/
lectures:
  - name: lec1
    url: /assets/lectures/distributed_applications/session1.zip
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
