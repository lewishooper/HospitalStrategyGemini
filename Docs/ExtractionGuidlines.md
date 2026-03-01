# Purpose
The overall purpose of this document is to outline the general purpose and set guidelines for extracting data from Ontario hospital websites

There are several distinct functions that will be used. These are not intended to be ran at the same time, but will use the general guidelines. The specific goals are outlined below. These extraction procedures will be run at different time and serve different purposes. The next section identifies the role. The section after this will define specific issues related to each role. 
## Baseline Information
There is a yaml file called "base_hospitals_validated.yaml" with the following structure as an example:
hospitals:
  - FAC: '592'
    name: NAPANEE LENNOX & ADDINGTON
    hospital_type: Small Hospital
    base_url: https://web.lacgh.napanee.on.ca
    base_url_validated: yes
    robots_allowed: yes
    last_validated: '2025-11-28'
    leadership_url: https://web.lacgh.napanee.on.ca/about/governance/
    notes: ''
    status:
The project folder is E:/Hospital_Strategic_Plans. The "base_hospitals_validated.yaml" is found in E:/Hospital_Strategic_Plans/code
This Yaml file should be used as a minimum Data set and may be expanded if needed, but should not carry too much dead information. 



## Extraction entities. 
The functions/roles will be:
    1. Extract a PDF of the hospital Strategic plans. 
    2. Extract the foundational guiding documents for the hospital 
    3. Extract the members of the executive team 
    4. Extract Board of directors of the hospital.
###  Specifications for each entity

1. Strategic plans are generally presented as a web page and a downloadable PDF. The PDF is preferred. There is currently a R script designed to find and download the strategic plans and is included in the Knowledge repository. "IdentifyAndDowloadStrategicPDF.R.   This code is quite complex and needs refactored. It was about 80% accurate.  The protocol for this code is  "refractor project plan for extracting hospital strategies.docx" and is in the Knowledge repository 
The goal of the extraction is to determine the dates covered by the plan, the key directions of the plan including Headings, Text describing the direction, and any planned actions to achieve the plan.

2. Extract foundational guiding documents. These may include Vision, Mission, Values, which are the usual and customary foundational documents but may include Purpose or other guiding documents.
The goal is to extract the Foundational documents, including the labels used (vision, mission, values, principles purpose, etc.)

3.  Extract the members of the executive team if highlighted in the webpage. This is usually the CEO, CNO, COS and Vice Presidents, but in smaller hospitals may include other Managers and directors. 
The Goal is to track the changes in executive teams on a monthly basis.
4.  Extract Board of directors of the hospital. Including Board chair, vice chair etc. 
The goal is simply tracking who is on the boards on a six month basis starting in september after Board re-elections.

## Issues

There is frequently an overlap between items 1 and 2, Many hospitals have Foundational documents in their strategic plan, and in their website. The preferred source is the website, and extraction from the strategic plan is a second choice

There is an overlap between items 3 and 4, Larger hospitals tend to separate  the lists, but will include the CEO the CNO and the COS in both lists. Those three are ex-officio  Board members. 
In smaller hospitals. In smaller hospitals Board members and Executive members may be in the same list.

## Summary

This project is intended to setup a framework that can be used by the four functions outlined above. It should simplify the setup and rules for extracting the data but does not need to extract the data itself those roles will be specified elsewhere. 

## Overall extraction principles. 

The extraction process will follow the best practices in web-scraping. e.g it will recognize and honor the robotxt rules that are in place and will pauses between searches. There will be an override, for the robotxt as I anticipate getting permission from a number of hospitals.
This will be done in an R environment, using Claude API and or Claude code as appropriate.

