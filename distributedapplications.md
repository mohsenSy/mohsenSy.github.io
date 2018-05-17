---
layout: default
c_name: Distributed  Applications
permalink: /university/distributed_applications/
lectures:
  - name: lec1
    url: /assets/lectures/distributed_applications/session1.zip
  - name: lec2
    url: /assets/lectures/distributed_applications/session2.zip
  - name: homework1
    url: /assets/lectures/distributed_applications/homework1.pdf
  - name: lec3
    url: /assets/lectures/distributed_applications/session3.zip
  - name: chat
    url: /assets/lectures/distributed_applications/chat.zip
  - name: lec5
    url: /assets/lectures/distributed_applications/session5.zip
  - name: lec6
    url: /assets/lectures/distributed_applications/session6.zip

---

{{ page.c_name }} lectures page

{% for lec in page.lectures %}
  <a href="{{ lec.url }}" target="_blank" >{{ lec.name }}</a>
{% endfor %}
