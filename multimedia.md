---
layout: default
c_name: Multimedia Systems
permalink: /university/multimedia/
lectures:
  - name: lec2
    url: /assets/lectures/multimediasystems/lec2.pdf
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
