#!/usr/bin/env python
# coding: utf-8

# In[313]:


def get_report(sample_VCF_path, phylotree_df_path="phylotree_df.pickle", top=50, xaxis_font_size=7):
    import pandas as pd
    import numpy as np
    import warnings
    import matplotlib.pyplot as plt
    warnings.filterwarnings("ignore")
    import pickle
    
    df = pd.read_pickle(phylotree_df_path)
    
    sample_VCF = pd.read_table(sample_VCF_path, header = None)
    sample_VCF.columns = ["chr", "pos", "rs", "ref", "var", "info0", "info1", "info2","info3", "info4"]
    sample_VCF_list = list(sample_VCF["pos"])
    print("Reference: https://www.phylotree.org")
    print("Credit: https://www.sciencedirect.com/science/article/abs/pii/S1875176815302432")
    print("\n")
    print("---------------Best Matching Haplogroup---------------")
    
    branch_order = []
    match_score = []
    levels = []
    parents = []
    parents_index = []
    is_leaf = []
    references = []
    for i in range(22):
        search = df[df["level"]==i]
        for branch in search.index:
            branch_order.append(search["branch"].loc[branch])
            var_position = search["pos"].loc[branch]
            matching = len(set(var_position).intersection(set(sample_VCF_list)))/len(sample_VCF_list)
            match_score.append(matching)
            levels.append(search["level"].loc[branch])
            parents.append(search["parent"].loc[branch])
            parents_index.append(search["parent_index"].loc[branch])
            is_leaf.append(search["is_leaf"].loc[branch])
            references.append(search["reference"].loc[branch])
            
    results = pd.DataFrame(branch_order)
    results.columns = ["branch"]
    results["%intersection"] = match_score
    results["level"] = levels
    results["parent"] = parents
    results["parent_index"] = parents_index
    results["is_leaf"] = is_leaf
    results["reference"] = references
    filtered = results[results["%intersection"]>0]
    
    colors = []
    for i in filtered.index:
        if filtered["level"].loc[i]==0:
            colors.append("darkblue")
        elif filtered["level"].loc[i]==1:
            colors.append("darkgreen")
        elif filtered["level"].loc[i]==2:
            colors.append("darkred")
        elif filtered["level"].loc[i]==3:
            colors.append("mediumblue")
        elif filtered["level"].loc[i]==4:
            colors.append("green")
        elif filtered["level"].loc[i]==5:
            colors.append("firebrick")
        elif filtered["level"].loc[i]==6:
            colors.append("blue")
        elif filtered["level"].loc[i]==7:
            colors.append("mediumseagreen")
        elif filtered["level"].loc[i]==8:
            colors.append("indianred")
        elif filtered["level"].loc[i]==9:
            colors.append("royalblue")
        elif filtered["level"].loc[i]==10:
            colors.append("limegreen")
        elif filtered["level"].loc[i]==11:
            colors.append("red")
        elif filtered["level"].loc[i]==12:
            colors.append("dodgerblue")
        elif filtered["level"].loc[i]==13:
            colors.append("lightgreen")
        elif filtered["level"].loc[i]==14:
            colors.append("orangered")
        elif filtered["level"].loc[i]==15:
            colors.append("deepskyblue")
        elif filtered["level"].loc[i]==16:
            colors.append("springgreen")
        elif filtered["level"].loc[i]==17:
            colors.append("coral")
        elif filtered["level"].loc[i]==18:
            colors.append("skyblue")
        elif filtered["level"].loc[i]==19:
            colors.append("greenyellow")
        elif filtered["level"].loc[i]==20:
            colors.append("lightsalmon")
        else:
            colors.append("aqua")
            
    ordered = filtered.sort_values(by="%intersection", ascending=False)
    selected = filtered[filtered["branch"].isin(ordered["branch"].head(top).to_list())]
    
    plt.bar(x=selected["branch"], height=selected["%intersection"], color=colors)
    plt.xticks(rotation=90)
    plt.title("Ratio of variants matched for each haplogroup")
    plt.xticks(fontsize=xaxis_font_size)
    plt.show()
    
    most_likely = results[results["%intersection"]==results["%intersection"].max()]
    for group in most_likely.index:
        ml_match_rate_avg = results["%intersection"].loc[group]/results["%intersection"].mean()
        most_likely_group = most_likely["branch"].loc[group]
        most_likely_rate = most_likely["%intersection"].loc[group]
        print("You are most likely belonging to haplogroup " + '\033[1m' + '\033[4m'+ '\033[94m' + f"{most_likely_group}" + '\033[0m')
        print('\033[1m' + '\033[4m'+ '\033[94m' + f"{most_likely_rate*100}%" + '\033[0m' + f" of your variant is matching haplogroup {most_likely_group}")
        print(f"Match rate to {most_likely_group} is {ml_match_rate_avg} times the average match rate to other haplogroups")
        mlref = most_likely["reference"].loc[group]
        print("Links to examples of mtDNA samples in same haplogroup are listed below. It should include geographical/origin information of the sample.")
        for ref in mlref:
            print(ref)

    print("\n")
    print("within the filtered bar graph, relationship between haplogroup is shown below:")
    path=""
    to = "-->"
    all_path = ""
    for i in selected.index[::-1]:
        parent = selected["parent"].loc[i]
        leaf = selected["branch"].loc[i]
        path = f"{leaf}"
        if parent!="root":
            while not selected[selected["branch"]==parent].empty:
                path = parent + to + path
                parent_loc = selected[selected["branch"]==parent]
                parent = parent_loc.iloc[0]["parent"]
        if to in path:
            if path not in all_path:
                print(path)
        all_path += path
    
    print("\n")
    print("---------------Phylotree Paths---------------")
    print("full relationship for non-zero matching rate haplogroups is shown below:")
    non_zero = results[results["%intersection"]>0]
    path=""
    all_path = ""
    for i in non_zero.index[::-1]:
        parent = non_zero["parent"].loc[i]
        leaf = non_zero["branch"].loc[i]
        path = f"{leaf}"
        if parent!="root":
            while not non_zero[non_zero["branch"]==parent].empty:
                path = parent + to + path
                parent_loc = non_zero[non_zero["branch"]==parent]
                parent = parent_loc.iloc[0]["parent"]
        if to in path:
            if path not in all_path:
                print(path)
        all_path += path
    
    print("\n")
    print("---------------Best Matching Path---------------")
    print("To see which leaf haplogroup (the leaf node groups in the phylotree) you belong to, variant-match-ratio for each path to the leaf haplogroup is computed")
    leafs = df[df["is_leaf"]==True]
    
    leafs_pos = []
    for i in leafs.index:
        leaf_pos = leafs["pos"].loc[i]
        parent = leafs["parent"].loc[i]
        parent_loc = df[df["branch"]==parent]
        parent_pos = parent_loc.iloc[0]["pos"]
        while not df[df["branch"]==parent].empty:
            leaf_pos = list(set(parent_pos).union(set(leaf_pos)))
            parent_loc = df[df["branch"]==parent]
            parent_pos = parent_loc.iloc[0]["pos"]
            parent = parent_loc.iloc[0]["parent"]
        leafs_pos.append(leaf_pos)

    leafs["path_pos"] = leafs_pos
    
    leaf_scores = []
    for i in range(len(leafs)):
        var_position = leafs.iloc[i]["path_pos"]
        matching = len(set(var_position).intersection(set(sample_VCF_list)))/len(sample_VCF_list)
        leaf_scores.append(matching)
    
    leafs["leaf_score"] = leaf_scores
    
    ordered_leaf = leafs.sort_values(by="leaf_score", ascending=False)
    plt.bar(x=ordered_leaf["branch"].head(top), height=ordered_leaf["leaf_score"].head(top))
    plt.xticks(rotation=90)
    plt.title("Full path variant-match-ratio for each leaf haplogroup")
    plt.xticks(fontsize=xaxis_font_size)
    plt.show()
    
    most_likely_leaf = leafs[leafs["leaf_score"]==leafs["leaf_score"].max()]
    for group in most_likely_leaf.index:
        most_likely_group = most_likely_leaf["branch"].loc[group]
        most_likely_rate = most_likely_leaf["leaf_score"].loc[group]
        print("You are most likely belonging to leaf haplogroup " + '\033[1m' + '\033[4m'+ '\033[94m' +  f"{most_likely_group}" + '\033[0m')
        print('\033[1m' + '\033[4m'+ '\033[94m' + f"{most_likely_rate*100}%" + '\033[0m' + f" of your variant is matching with the path to {most_likely_group}")
        
        leaf = most_likely_group
        parent = df[df["branch"]==most_likely_leaf["parent"].loc[group]].iloc[0]["branch"]
        path = leaf
        while not df[df["branch"]==parent].empty:
            path = parent + to + path
            parent_loc = df[df["branch"]==parent]
            parent = parent_loc.iloc[0]["parent"]
        print(path)
        mlref = most_likely_leaf["reference"].loc[group]
        print("Links to examples of mtDNA samples in same haplogroup are listed below. It should include geographical/origin information of the sample.")
        for ref in mlref:
            print(ref)
        
        print("\n")
    
    return (results, filtered, leafs)
    


# In[ ]:




