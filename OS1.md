---
layout: default
c_name: Operating Systems 1
permalink: /university/OS1/
lectures:
  - name: lec1
    url: /assets/lectures/os1/lec1.pdf
  - name: lec3
    url: /assets/lectures/os1/lec3.pdf
  - name: lec4
    url: /assets/lectures/os1/lec4.pdf
  - name: lec5
    url: /assets/lectures/os1/lec5.pdf
  - name: lec6
    url: /assets/lectures/os1/lec6.pdf
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
