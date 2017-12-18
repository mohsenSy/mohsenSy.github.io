---
layout: default
c_name: Multimedia Systems
permalink: /university/multimedia/
lectures:
  - name: lec2
    url: /assets/lectures/multimediasystems/lec2.pdf
  - name: lec3
    url: /assets/lectures/multimediasystems/lec3.pdf
  - name: lec4
    url: /assets/lectures/multimediasystems/lec4.pdf
  - name: lec5
    url: /assets/lectures/multimediasystems/lec5.pdf
  - name: lec6
    url: /assets/lectures/multimediasystems/lec6.pdf
  - name: lec7
    url: /assets/lectures/multimediasystems/lec7.rar
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
