---
layout: default
c_name: Operating Systems 1
permalink: /OS1/
lectures:
  - name: lec1
    url: /assets/lectures/os1/lec1.pdf
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}">{{ lec.name }}</a>
{% endfor %}
