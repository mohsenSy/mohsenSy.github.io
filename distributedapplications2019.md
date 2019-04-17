---
layout: default
c_name: Distributed  Applications 2019
permalink: /university/distributed_applications_2019/
lectures:
  - name: session1
    url: /assets/lectures/distributed_applications_2019/session1.zip
  - name: session2
    url: /assets/lectures/distributed_applications_2019/session2.zip
  - name: session3
    url: /assets/lectures/distributed_applications_2019/session3.zip
  - name: session4
    url: /assets/lectures/distributed_applications_2019/session4.pdf
  - name: homework1
    url: /assets/lectures/distributed_applications_2019/homework1.zip
  - name: session5
    url: /assets/lectures/distributed_applications_2019/session5.zip
  - name: session6
    url: /assets/lectures/distributed_applications_2019/session6.zip
---

{{ page.c_name }} sessions page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
