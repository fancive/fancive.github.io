---
title: "[paper reading]AIOps: Real-World Challenges and Research Innovations"
date: 2023-03-18T13:35:19+08:00
draft: false

categories:
- software engineering

tags:
- paper reading
- AIOps
---

- link: https://ieeexplore.ieee.org/abstract/document/8802836

## first pass

5-10 mins

1. title, abstract, and introduction
2. section and sub-section headings
3. conclusions
4. references

### question

**Category: What type of paper is this? A measurement paper? An analysis of an existing system? A description of a research prototype?**

It is a descriptive paper that discusses the challenges and innovations related to the implementation of AIOps in real-world IT operations.

**Context: Which other papers is it related to? Which theoretical bases were used to analyze the problem?**

P. Huang, C. Guo et al., "Capturing and Enhancing In Situ System Observability for Failure Detection", *Proceedings of OSDI*, 2018.

Y. Xu, K. Sui et al., "Improving Service Availability of Cloud Systems by Predicting Disk Error", *Proceedings of USNIX ATC*, 2018.

Q. Lin, K. Hsieh et al., "Predicting Node Failure in Cloud Service Systems", *proceedings of FSE*, 2018.

Some of the theoretical frameworks that are relevant to AIOps include supervised and unsupervised learning, reinforcement learning, deep learning, and natural language processing.

**Correctness: Do the assumptions appear to be valid?**


**Contributions: What are the paper’s main contributions?**

1. talking about the motivation and importance of AIOps; 
2. describing the real-world challenges of building AIOps solutions based on the experience in Microsoft
3. introducing a set of sample AIOps solutions that have successfully benefited Microsoft service products
4. sharing some learnings from AIOps practice.

**Clarity: Is the paper well written?**

it appears to be well-organized, it introduces the the vision, challenge and innovation of AIOps.

## second pass

1 hour

1. ﬁgures(插图), diagrams(示意图、流程图) and other illustrations
2. mark relevant unread references

### question

**summarize the main thrust & some evidence**

the vision of AIOps

1. High service intelligence. predict its future status(quality, cost, workload)
2. High customer satisfaction. understand customer usage behavior and take proactive actions(configuration, quality issue)
3. High engineering productivity. developers are relieved of tedious tasks(investigating, fixing repeated issues)

challenges of building AIOps

1. methodologies and mindset(different from the traditional engineering mindset, not ai solves all)
2. Engineering changes (improvement of data quality and quantity)
3. building ML models (no clear ground truth labels, complex dependencies, huge manual efforts)

innovations on AIOps

1. Cross-disciplinary research
2. Close collaboration between academia and industry

## third pass

1 / 4-5 hour

**re-implement the paper: that is, making the same assumptions as the authors, re-create the work**