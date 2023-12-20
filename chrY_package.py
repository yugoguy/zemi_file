#!/usr/bin/env python
# coding: utf-8

# In[10]:


def get_result(vcf_path, choice=True):
    #imports and classification dataframe preparation
    import pandas as pd
    import requests
    import matplotlib.pyplot as plt
    if choice: 
        print("dataframe used in this code can be updated.")
        print("if you have already updated the dataframe recently using this code, it is recommended not to update since it should be already updated.")
        print("by default, last update is 2023/12/18")
        print("please note that updating the dataframe can take time (5~30min)")
        update_ybrowse = input("update the dataframe? (y/n)")
        if update_ybrowse=="y":
            update_ybrowse=True
        else:
            update_ybrowse=False
        if update_ybrowse:
            print("updating ISOGG Ybrowse SNP index. it may take several minutes to update!")
            isyb = pd.read_csv("https://ybrowse.org/gbrowse2/gff/snps_hg38.csv")
            isyb.to_csv("snps_hg38.csv")
        else:
            isyb = pd.read_csv("snps_hg38.csv", header=0)
        print("basic dataframe for analysis is ready!")
        print("\n")
        
        #considering implementation
        """
        import pickle
        print("this code also use extra dataframe extracted from YFull.")
        print("this dataframe can be updated too.")
        print("if you have already updated the dataframe recently using this code, it is recommended not to update since it should be already updated.")
        print("by default, last update is 2023/12/18")
        print("please note that updating the dataframe can take time (5~30min)")
        update_yfull = input("update the extra dataframe? (y/n)")
        if update_yfull=="y":
            update_yfull=True
        else:
            update_yfull=False
        if update_yfull:
            print("updating YFull SNP index. it may take several minutes to update!")
            htmlraw = requests.get(f"https://www.yfull.com/snp-list/?page={1}")
            content = pd.read_html(htmlraw.content, header=0)
            YFull = content[1]
            page = 2
            while True:
                try: 
                    htmlraw = requests.get(f"https://www.yfull.com/snp-list/?page={page}")
                    content = pd.read_html(htmlraw.content, header=0)
                    current = content[1]
                    YFull = pd.concat([YFull,current])
                    page+=1
                except ValueError:
                    break
            YFull.to_pickle("YFull_updates.sav")
        else:
            YFull = pd.read_pickle("YFull_updates.sav")
        yfull = YFull[["SNP-ID", "Build38", "ANC", "DER", "Branch"]]
        yfull.columns = [["SNP-ID", "pos38", "ref", "var", "branch"]]
        print("extra dataframe for analysis is ready!")
        print("\n")
    else:
        isyb = pd.read_csv("snps_hg38.csv", header=0)
        YFull = pd.read_pickle("YFull_updates.sav")
    """
    # vcf file preparation
    vcf = pd.read_table(vcf_path, header=None)
    vcfy = vcf[vcf[0]=="chrY"]
    var = vcfy[[1,2,3,4]]
    var.columns = [["GRCh38pos" ,"rs", "ref", "var"]]
    
    # find matches
    matched = pd.DataFrame()
    for i in range(len(var)):
        print(i)
        varpos = var.iloc[i]["GRCh38pos"]
        varvar = var.iloc[i]["var"]
        df = isyb[(isyb["start"]==varpos)&(isyb["allele_der"]==varvar)]
        matched = pd.concat([matched,df[["ID","YCC_haplogroup","ISOGG_haplogroup", "start", "allele_der"]]])
        
    plt.bar(height=matched.ISOGG_haplogroup.value_counts().tolist()[0:20], x=matched.ISOGG_haplogroup.value_counts().index[0:20])
    plt.xticks(rotation=90)
    plt.title("number of prediction per ISOGG haplogroup (duplicate variant not considered)")
    plt.show()
    
    plt.bar(height=matched.YCC_haplogroup.value_counts().tolist()[0:20], x=matched.YCC_haplogroup.value_counts().index[0:20])
    plt.xticks(rotation=90)
    plt.title("number of prediction per YCC haplogroup (duplicate variant not considered)")
    plt.show()
    
    alt_dup = matched.drop_duplicates(subset=["start", "allele_der"])
    plt.bar(height=alt_dup.ISOGG_haplogroup.value_counts().tolist()[0:20], x=alt_dup.ISOGG_haplogroup.value_counts().index[0:20])
    plt.xticks(rotation=90)
    plt.title("number of prediction per ISOGG haplogroup (duplicate variant deleted)")
    plt.show()
    
    plt.bar(height=alt_dup.YCC_haplogroup.value_counts().tolist()[0:20], x=alt_dup.YCC_haplogroup.value_counts().index[0:20])
    plt.xticks(rotation=90)
    plt.title("number of prediction per YCC haplogroup (duplicate variant deleted)")
    plt.show()

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




