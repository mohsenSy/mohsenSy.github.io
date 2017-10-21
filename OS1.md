---
layout: default
c_name: Operating Systems 1
permalink: /university/OS1/
lectures:
  - name: lec1
    url: /assets/lectures/os1/lec1.pdf
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
