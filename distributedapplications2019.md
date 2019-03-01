---
layout: default
c_name: Distributed  Applications 2019
permalink: /university/distributed_applications_2019/
lectures:
  - name: lec1
    url: /assets/lectures/distributed_applications_2019/session1.zip
---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
