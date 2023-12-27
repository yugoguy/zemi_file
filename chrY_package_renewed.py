#!/usr/bin/env python
# coding: utf-8

# In[1]:


def get_result(vcf_path, choice=True, vcf_df_formatted_path=None):
    #imports and classification dataframe preparation
    import pandas as pd
    import pickle
    import matplotlib.pyplot as plt
    import numpy as np
    get_ipython().run_line_magic('matplotlib', 'inline')
    
    isogg = pd.read_pickle("ISOGG_dataframe.sav")
    print("Reading VCF file...")
    
    # vcf file preparation
    if vcf_df_formatted_path:
        print("reads pickle saved dataframe with GRCh38 position, reference allele, and variant allele list as columns")
        var = pd.read_pickle(vcf_df_formatted_path)
        var.columns = [["GRCh38pos" ,"ref", "var"]]
    else:  
        vcf = pd.read_table(vcf_path, header=None)
        vcfy = vcf[vcf[0]=="chrY"]
        vcfy = vcfy.reset_index(drop=True)
        var_info = []
        for i in vcfy.index:
            var_info.append(vcfy.iloc[i][9].split(":")[0])
        vcfy["var_info"] = var_info
        vars_ = []
        for i in vcfy.index:
            var = []
            var_info = vcfy.iloc[i]["var_info"]
            alt_which = var_info.split("/")
            alt_choice = vcfy.iloc[i][4].split(",")
            for j in alt_which:
                if int(j)!=0:
                    if alt_choice[int(j)-1] not in var:
                        var.append(alt_choice[int(j)-1])
            vars_.append(var)
        vcfy["vars"] = vars_
        var = vcfy[[1,3,"vars"]]
        var.columns = [["GRCh38pos" ,"ref", "var"]]

    # find matches
    print("Analyzing...")
    matched = pd.DataFrame()
    for i in range(len(var)):
        varpos = var.iloc[i]["GRCh38pos"]
        varvar = var.iloc[i]["var"]
        varref = var.iloc[i]["ref"]
        df = isogg[(isogg["Build 38 #"]==varpos)&(isogg["var"].isin(varvar))&(isogg["ref"]==varref)]
        matched = pd.concat([matched,df])
    print(f"{len(matched)} variants matched!")
    print("\n")
    print("Bar graph below shows number of variants matched (>0) for each haplogroup:")
    plt.bar(height=matched.groupby("Haplogroup").count()["score"].values, x=matched.groupby("Haplogroup").count()["score"].index)
    plt.title("Count matched variants")
    plt.xticks(rotation=90)
    plt.show()
    
    print("Bar graph below shows percentage(%) of variants matched (>0) for each haplogroup:")
    plt.bar(height=matched.groupby("Haplogroup")["score"].sum().values, x=matched.groupby("Haplogroup")["score"].sum().index)
    plt.title("ratio of variants matched")
    plt.xticks(rotation=90)
    plt.show()
    
    print("Bar graph below shows the score1 (equation provided in title) for each haplogroup:")
    result = (np.log(matched.groupby("Haplogroup").count()+1)["score"].multiply(matched.groupby("Haplogroup")["score"].sum()))/np.log(matched.groupby("Haplogroup").count()+1)["score"].multiply(matched.groupby("Haplogroup")["score"].sum()).max()
    plt.bar(height=result.values, x=result.index)
    plt.title("Score1: log(count+1)*ratio")
    plt.xticks(rotation=90)
    plt.show()
    
    print("Bar graph below shows the score2 (equation provided in title) for each haplogroup:")
    result2 = (matched.groupby("Haplogroup")["score"].sum()*3/(2/matched.groupby("Haplogroup").count()["score"] + matched.groupby("Haplogroup")["score"].sum()))/(matched.groupby("Haplogroup")["score"].sum()*3/(2/matched.groupby("Haplogroup").count()["score"] + matched.groupby("Haplogroup")["score"].sum())).max()
    plt.bar(height=result2.values, x=result2.index)
    plt.title("Score2: ratio*harmonic_average(2/count, ratio)")
    plt.xticks(rotation=90)
    plt.show()
    
    labels = result.index
    log_weight_ratio = result.values
    weighted_harmonic = result2.values
    ratio = matched.groupby("Haplogroup")["score"].sum()
    count = matched.groupby("Haplogroup").count()["score"]/matched.groupby("Haplogroup").count()["score"].max()

    x = np.arange(len(labels))  # the label locations
    width = 0.2  # the width of the bars

    fig, ax = plt.subplots()
    rects1 = ax.bar(x - 0.3, log_weight_ratio, width, label='score1(log)')
    rects2 = ax.bar(x - 0.1, weighted_harmonic, width, label='score2(har)')
    rects3 = ax.bar(x + 0.1, ratio, width, label='ratio')
    rects4 = ax.bar(x + 0.3, count, width, label='count')


    # Add some text for labels, title and custom x-axis tick labels, etc.
    ax.set_ylabel('Scores')
    ax.set_title('Scores by halogroups')
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend(loc='upper center', bbox_to_anchor=(0.5, 1.035),
              fancybox=True, shadow=True, ncol=5)

    print("Below is the integrated bar graph of 4 measures for each haplogroup:")
    fig.tight_layout()
    plt.xticks(rotation=90)
    plt.show()
    
    paths = []
    for hg in result.index:
        path = f"{hg}"
        hg_id = isogg[isogg["Haplogroup"]==hg].index[0]
        parent = isogg.iloc[hg_id]["parent"]
        #print(parent)
        while (parent != "root") & (parent in result):
            path = f"{parent}" + " -> " + path
            hg_id = isogg[isogg["Haplogroup"]==parent].index[0]
            parent = isogg.iloc[hg_id]["parent"]
        paths.append(path)

    for path in paths:
        #print(path)
        other = [p for p in paths if p!=path]
        for o in other:
            if path in o:
                #print("removing")
                paths = [i for i in paths if i != path]
                break
        #print(paths)
        
    print("Below arrow diagram shows the relatioship between matched haplogroups:")
    for i in paths:
        print(i)
        
    arrow = "->"
    longest = ""
    longest_len = -1
    for path in paths:
        length = len(path.split(arrow))
        if length>longest_len:
            longest = path
            longest_len = length
    
    print("\n")
    print(f"According to score1, you are most likely belong to {result[result==1].index[0]}")
    print("\n")
    print(f"According to score2, you are most likely belong to {result2[result2==1].index[0]}")
    print("\n")
    print(f"According to the arrow diagrams, you most likely belong to {longest}")
    print("note: if length of the arrow diagram is equal, the first path is arbitrarily chosen. If this is the case, it is better to refer to score1 or score2 results")

    return matched


# In[18]:


# Assistant is created with gpt-4-0613 model with following instruction: You are a professional data analyst. You are also Professional in genetics especially about Y chromosome haplogroups. You are professional in visualizing the given information. You always answer with visualization you are asked for, and also with text explaining the haplogroup in given list. Always give further explanations on the regions for top haplogroups, and be very specific about regions/ethnicity/era if possible.

def get_gpt_output(matched, apikey):
    from openai import OpenAI
    from openai.types.beta.threads import MessageContentImageFile, MessageContentText
    import matplotlib.image as mpimg
    print("please note that this imformation is generated by GPT model, so accuracy is not guranteed.")
    print("for better informtion, please view following links.")
    print("https://yhrd.org/pages/resources/ysnps")
    print("https://www.familytreedna.com/public/y-dna-haplotree")
    print("https://www.yfull.com/tree/")
    print("https://en.wikipedia.org/wiki/Human_Y-chromosome_DNA_haplogroup")
    print("\n")
    
    haplogroup = [i for i in result.ISOGG_haplogroup.value_counts().index if i not in ["unknown", "not listed"]][0:10]
    count = [i for i in result.ISOGG_haplogroup.value_counts().tolist() if i not in ["unknown", "not listed"]][0:10]

    prompt1 = f"""
    top 10 haplogroups:
    {haplogroup}
    corresponding number of prediction (in same order with top 10 haplogroup):
    {count}
    """

    prompt2 = """
    State top 3 region candidates of this individual's Y chromosome origin for each haplogroups listed as "top 10 haplogroups". Then output one integrated world map (using geopandas)  indicating those regions. The color intensity of the region in world map should be proportional to the corresponding number of prediction.

    example code: (do not just duplicate, especially for choice of regions)

    import geopandas as gpd
    import matplotlib.pyplot as plt

    # Haplogroup data and corresponding prediction numbers
    haplogroups = [
        'O1b1a1a2a-F5506/SK1665', 'O2a1c1a1a1a1g', 'R1b1a2a1a1d1', 'R1b1a2a1a2b1b', 
        'LT', 'C2b*', 'A00b', 'O1b1a1a2a-F5506/SK1661', 'D1a1a2-F1070', 'BT'
    ]
    predictions = [2300, 1100, 654, 435, 207, 150, 103, 90, 45, 10]

    # Mapping haplogroups to their top 3 regions
    haplogroup_regions = {
        'O1b1a1a2a-F5506/SK1665': ['China', 'Taiwan', 'Vietnam'],
        'O2a1c1a1a1a1g': ['Vietnam', 'China', 'Taiwan'],
        'R1b1a2a1a1d1': ['France', 'Spain', 'United Kingdom'],
        'R1b1a2a1a2b1b': ['Ireland', 'United Kingdom', 'United States'],
        'LT': ['India', 'Iran', 'Turkey'],
        'C2b*': ['Mongolia', 'Russia', 'United States'],
        'A00b': ['Cameroon'],
        'O1b1a1a2a-F5506/SK1661': ['China', 'Taiwan', 'Vietnam'],
        'D1a1a2-F1070': ['China', 'Tibet', 'Kazakhstan'],
        'BT': ['Nigeria', 'Saudi Arabia', 'India']
    }

    # Creating a dictionary to accumulate the predictions for each country
    country_predictions = {}
    for haplogroup, regions in haplogroup_regions.items():
        prediction = predictions[haplogroups.index(haplogroup)]
        for country in regions:
            if country in country_predictions:
                country_predictions[country] += prediction
            else:
                country_predictions[country] = prediction

    # Load the world map
    world = gpd.read_file(gpd.datasets.get_path('naturalearth_lowres'))

    # Add prediction data to the world map
    world['Prediction'] = world['name'].map(country_predictions).fillna(0)

    # Visualization
    plt.figure(figsize=(15, 10))
    world.plot(column='Prediction', cmap='Reds', legend=True, edgecolor='black')
    plt.title('Predicted Regions of Y-Chromosome Origin')
    plt.show()
    """
    prompt = prompt1 + "\n" + prompt2

    client = OpenAI(api_key=apikey)

    empty_thread = client.beta.threads.create()
    thread_id = empty_thread.id

    client.beta.threads.messages.create(
        thread_id=thread_id,
        role="user",
        content=prompt,
    )

    run = client.beta.threads.runs.create(
        thread_id=thread_id,
        assistant_id="asst_TlcrQ3mlz8Vzf0pr9gTGc50M",
    )
    run_id = run.id

    run_retrieve = client.beta.threads.runs.retrieve(
        thread_id=thread_id,
        run_id=run_id,
    )

    run_retrieve = client.beta.threads.runs.retrieve(
        thread_id=thread_id,
        run_id=run_id,
    )
    
    while run_retrieve.status !="completed":
        run_retrieve = client.beta.threads.runs.retrieve(
            thread_id=thread_id,
            run_id=run_id,
        )

    messages = client.beta.threads.messages.list(
        thread_id=thread_id
    )
        
    print(messages.data)
    
    file_id = messages.data[0].content[0].image_file.file_id

    text_ = messages.data[0].content[1].text.value
       
    client = OpenAI(api_key=apikey)

    image_data = client.files.content(file_id)
    image_data_bytes = image_data.read()

    with open(f"{file_id}.png", "wb") as file:
        file.write(image_data_bytes)

    plt.title("Haplogroup Region World Map")
    plt.axis('off')

    image = mpimg.imread(f"{file_id}.png")
    plt.imshow(image)
    plt.show()

    print(text_)
    
    return messages



# In[ ]:




