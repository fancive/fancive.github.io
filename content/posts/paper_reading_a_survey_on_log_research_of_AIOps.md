---
title: "[Paper reading] A Survey On Log Research Of AIOps: Methods and Trends"
date: 2023-03-25T13:43:03+08:00
draft: false

categories:
- software engineering

tags:
- paper reading
- AIOps
---

# first pass

5-10 mins

1. title, abstract, and introduction
2. section and sub-section headings
3. conclusions
4. references
<!--more-->
## question

**Category: What type of paper is this? A measurement paper? An analysis of an existing system? A description of a research prototype?**

It’s a survey paper on the methods and trend on log based AIOps.

It does not seem to focus on a specific system or prototype, but rather explore the current state of research in the field.

**Context: Which other papers is it related to? Which theoretical bases were used to analyze the problem?**

1. S. He, J. Zhu, P. He and M. R. Lyu, "Experience Report: System Log Analysis for Anomaly Detection," *2016 IEEE 27th International Symposium on Software Reliability Engineering (ISSRE)*, Ottawa, ON, Canada, 2016, pp. 207-218, doi: 10.1109/ISSRE.2016.21.
2. R. B. Yadav, P. S. Kumar and S. V. Dhavale, "A Survey on Log Anomaly Detection using Deep Learning," *2020 8th International Conference on Reliability, Infocom Technologies and Optimization (Trends and Future Directions) (ICRITO)*, Noida, India, 2020, pp. 1215-1220, doi: 10.1109/ICRITO48877.2020.9197818.
3. R. Vinayakumar, K. P. Soman and P. Poornachandran, "Long short-term memory based operation log anomaly detection," *2017 International Conference on Advances in Computing, Communications and Informatics (ICACCI)*, Udupi, India, 2017, pp. 236-242, doi: 10.1109/ICACCI.2017.8125846.

The paper explores the use of SVM, NLP and decision tree for log analysis and discusses several data anylysis techniques, such as clustering and time series analysis.

**Correctness: Do the assumptions appear to be valid?**

The paper conducted a systematic review to investigate the motheds and trend in log research for AIOps. The author found that the use of log data is essential for AIOps and machine learning techniques are widely used in log research.

Based on the survey , the assumptions appear to be valid.

**Contributions: What are the paper’s main contributions?**

The paper presents a comprehencive survey of the research on log analysis in the field of AIOps.

1. The paper reviews various techniques and algorithms used for log analysis in AIOps, including statistical analysis, machine learning, NLP and graph analysis.
2. The paper discusses the application of log analysis of AIOps, including fault detection and diagnosis, anomaly detection, root cause analysis and predictive maintenance.
3. The paper indentify the key chanllenges in log analysis for AIOps, including the vast amount of data, the need of real-time analysis and the need to integrate multiple data sources.

**Clarity: Is the paper well written?**

It apears to be well-organized and follows a logical stucture. It starts by providing background information on AIOps and log management, followed by a review on related work in the field.The paper then descibes the methodology used to conduct the survey and presents the key findings. The discussion section analyzes the results. The conclusion summarizes the main contributions of the study and outlines future direction of study.  

# second pass

1 hour

1. ﬁgures(插图), diagrams(示意图、流程图) and other illustrations
2. mark relevant unread references

## question

**summarize the main thrust**

The main thrust of the survey is to identify the challenges and opportunities in using AI for log analysis, and to understand the current state of research in this area.

The survey identifies several trends in the use of AI for log analysis. One is the use of unsupervised learning. Another is the use of deep learning.

There are still many challenges to be addressed, such as the lack of labelled data, the complexity of log data and the needs of industrial deployment.

<center><img src="./images/log_4_ops.png" width="50%" /></center>

![log_4_ops](/images/img/log_4_ops.png)

**some evidence**

# third pass

1 / 4-5 hour

**re-implement the paper: that is, making the same assumptions as the authors, re-create the work**
