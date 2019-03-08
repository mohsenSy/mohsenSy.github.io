---
layout: default
c_name: Distributed  Applications 2019
permalink: /university/distributed_applications_2019/
lectures:
  - name: session1
    url: /assets/lectures/distributed_applications_2019/session1.zip
  - name: session2
    url: /assets/lectures/distributed_applications_2019/session2.zip
---

{{ page.c_name }} sessions page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
