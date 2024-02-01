#!/usr/bin/env python
# coding: utf-8

# In[78]:


def get_result(vcf_path, update=False, vcf_df_formatted_path=None):
    #imports and classification dataframe preparation
    import pandas as pd
    import pickle
    import matplotlib.pyplot as plt
    import numpy as np
    get_ipython().run_line_magic('matplotlib', 'inline')
    import networkx as nx
    import json
    import requests
    
    print("Credit: YFull")
    print("https://www.yfull.com/tree/")
    print("https://github.com/YFullTeam/YTree")
    print("\n")
    
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
    
    # analysis snp database preparation 
    tree = pd.read_pickle(open("yfull_tree_info.sav", 'rb'))
    snps = pd.read_pickle(open("full_snps.sav", 'rb'))
    
    # update tree choice
    if update:
        update = input("update the information used in the analysis? this may take a while [y/n]")
    
    if update=="y":
        def recur_tree(tree=None, init=True):
            if init:
                tree = None
                response = requests.get("https://raw.githubusercontent.com/YFullTeam/YTree/master/current_tree.json")
                tree = pd.DataFrame(json.loads(response.content))
                tree["parent"] = "root"
                tree["id"] = "Y Chromosomal Adam"
            children = []
            child_dicts = []
            if "children" in tree.columns:
                for i in range(len(tree)):
                    child_dict = tree.iloc[i]["children"]
                    child_dicts.append(child_dict)
                hash_string = ""
                for child_dict in child_dicts:
                    hash_ = hash_string + json.dumps(child_dict)
                hash_ = hash(hash_string)
                for child_dict in child_dicts:
                    index_ = [0] if "children" not in child_dict.keys() else None
                    child_df = pd.DataFrame(child_dict, index=index_)
                    child_df["parent"] = hash_
                    children.append(child_df)
                for child in children:
                    tree = pd.concat([tree, recur_tree(tree=child, init=False)])
            return tree

        def clean_tree(tree):
            tree = tree.reset_index(drop=True).fillna("leaf")

            listed_snps = []
            for i in tree.index:
                snps = re.split('/|, ', tree.iloc[i]["snps"])
                listed_snps.append(snps)
            tree["snp_list"] = listed_snps

            counts = []
            scores = []
            for i in tree.index:
                snp_list = tree.iloc[i]["snps"].split(",")
                count = len(snp_list)
                if snp_list == ['']:
                    count = 0
                counts.append(count)
                if count!=0:
                    score = 1/count
                else:
                    score = 0
                scores.append(score)
            tree["count"] = counts
            tree["score"] = scores

            childs = tree.groupby("id")["children"].apply(list)

            hashes = []
            for i in tree.index:
                hash_ = hash(json.dumps(tree.iloc[i]["children"]))
                hashes.append(hash_)
            tree["hash"] = hashes

            return tree
        
        if update=="y":
            tree = clean_tree(recur_tree())

        # update ybrowse master file choice

        snps_list_slashed = []
        for i in tree.index:
            snps = tree.iloc[i]["snps"]
            snps_split = snps.split(",")
            for snp in snps_split:
                snps_list_slashed.append(snp)

        snps_list_slash_firsts = []
        for snp in snps_list_slashed:
            un_spaced = snp.replace(" ", "")
            slashed = un_spaced.split("/")
            selected = un_spaced.split("/")[0]
            snps_list_slash_firsts.append(selected)

        snps_list_slash_firsts = list(filter(None, snps_list_slash_firsts))
        snps_unique = list(set(snps_list_slash_firsts))
        if update=="y":
            print("updating ISOGG Ybrowse SNP index. it may take several minutes to update!")
            isyb = pd.read_csv("https://ybrowse.org/gbrowse2/gff/snps_hg38.csv")
            isyb.to_csv("snps_hg38.csv")

        # update yfull snp index choice
        if update=="y":
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
        yfull = YFull[["SNP-ID", "Build38", "ANC", "DER", "Branch"]]
        yfull.columns = [["SNP-ID", "pos38", "ref", "var", "branch"]]
        print("yfull snps info updated!")
        print("\n")

        isyb_snp = isyb[["Name", "allele_anc", "allele_der", "start"]]
        isyb_snp.columns = ["snp", "ref", "var", "pos"]
        yfull_snp = yfull[["SNP-ID", "ANC", "DER", "Build38"]]
        yfull_snp.columns = ["snp", "ref", "var", "pos"]

        isyb_intree = isyb_snp[isyb_snp["snp"].isin(snps_unique)].drop_duplicates()
        yfull_intree = yfull_snp[yfull_snp["snp"].isin(snps_unique)].drop_duplicates()

        isyb_yfull_intree = pd.concat([isyb_intree, yfull_intree]).drop_duplicates()
        inspect_isyb_yfull_intree = isyb_yfull_intree.groupby("snp").count().sort_values(by="ref", ascending=False)
        dup_list = inspect_isyb_yfull_intree[inspect_isyb_yfull_intree["ref"]>=2].index
        dups = isyb_yfull_intree[(isyb_yfull_intree["snp"].isin(dup_list))].sort_values(by="snp").reset_index(drop=True)
        isyb_intree_fix = isyb_snp[(isyb_snp["snp"].isin(snps_unique))&(isyb_snp["snp"].isin(dup_list)==False)].drop_duplicates()
        isyb_yfull_intree_fix = pd.concat([isyb_intree_fix, yfull_intree]).drop_duplicates()

        missing = list(set(snps_unique).difference(set(isyb_yfull_intree_fix["snp"].tolist())))

        # update ybrowse search choice
        dfs = {}
        not_found = []
        counter = 0
        for snp in missing:
            try: 
                htmlraw = requests.get(f"https://ybrowse.org/gb2/gbrowse_details/chrY?ref=chrY;name={snp};class=Sequence;db_id=chrY%3Adatabase")
                df = pd.read_html(htmlraw.content, header=None)[0]
                dfs[f"{snp}"]=df
            except ValueError:
                not_found.append(snp)

        ybrowse_found = []
        for key in dfs.keys():
            df = dfs[key]
            pos_yb = int(df.iloc[3][1].split(":")[1].split("..")[0])
            found_info = [df.iloc[0][1], df.iloc[5][1], df.iloc[6][1], pos_yb]
            ybrowse_found.append(found_info)
        ybrowse_found_df = pd.DataFrame(ybrowse_found)
        ybrowse_found_df.columns = ["snp", "ref", "var", "pos"]

        full_snps = pd.concat([isyb_yfull_intree_fix, ybrowse_found_df]).reset_index(drop=True)
        
        save = input("analysis database updated. overwrite the database for later use? [y/n]")
        if save=="y":
            pickle.dump(tree, open("yfull_tree_info.sav", 'wb'))
            pickle.dump(full_snps, open("full_snps.sav", 'wb'))
            
    # find variant matches
    print("Analyzing...")
    matched = pd.DataFrame()
    for i in range(len(var)):
        varpos = var.iloc[i]["GRCh38pos"]
        varvar = var.iloc[i]["var"]
        varref = var.iloc[i]["ref"]
        df = snps[(snps["pos"]==varpos)&(snps["var"].isin(varvar))&(snps["ref"]==varref)]
        matched = pd.concat([matched,df])
    
    print(f"{len(matched)} variants matched")
    
    # find yfull haplogroup match
    matched = matched.reset_index(drop=True)
    tree["match"] = 0
    tree.drop_duplicates(subset=["id"], inplace=True)
    
    for i in matched.index:
        matched_snp = matched.iloc[i]["snp"]
        tree.loc[tree['snp_list'].apply(lambda x: matched_snp in x),"match"] += 1

    # find scores
    filtered_tree = tree[tree["match"]>0]
    filtered_tree = filtered_tree[["id", "match", "score"]]

    scores = filtered_tree.groupby("id").sum()
    scores["percent"] = scores["match"] * scores["score"]
    scores["log_score"] = scores["percent"] * np.log2(scores["match"]+1)
    scores["harmonic_score"] = scores["percent"] * 2/(scores["percent"] + 1/scores["match"])
    
    response = requests.get("https://raw.githubusercontent.com/YFullTeam/YTree/master/current_tree.json")
    json_data = json.loads(response.content)
    def build_parent_map(node, parent_map, parent_id=None):
        node_id = node.get('id')
        parent_map[node_id] = parent_id
        for child in node.get('children', []):
            build_parent_map(child, parent_map, node_id)

    def direct_path(node_id, parent_map, target_ids):
        if node_id in parent_map and parent_map[node_id] in target_ids:
            return [parent_map[node_id], node_id]
        return []

    def find_direct_paths(nodes_list, parent_map):
        paths = []
        for node_id in nodes_list:
            if node_id in parent_map:  # Ensure the node is in the tree
                path = direct_path(node_id, parent_map, nodes_list)
                if path:  # Include only if a direct path is found
                    paths.append(path)
        return paths
    # Main execution
    if __name__ == "__main__":
        parent_map = {}
        build_parent_map(json_data, parent_map)  # Assuming json_data is your root node
    
    nodes_list = scores.index.to_list()  # Example list, replace with actual IDs
    paths = find_direct_paths(nodes_list, parent_map)
    
    def merge_overlapping_paths(paths):
        merged = True
        while merged:
            merged = False
            for i in range(len(paths)):
                for j in range(i + 1, len(paths)):
                    # Check if the last node of path i is the first node of path j or vice versa
                    if paths[i][-1] == paths[j][0]:
                        paths[i].extend(paths[j][1:])
                        paths.pop(j)
                        merged = True
                        break
                    elif paths[i][0] == paths[j][-1]:
                        paths[j].extend(paths[i][1:])
                        paths.pop(i)
                        merged = True
                        break
                if merged:
                    break  # Restart scanning if any merge occurred
        return paths
    longest_paths = merge_overlapping_paths(paths)
        
    def visualize_paths_nx_vertical_with_longest_path_color(paths):
        G = nx.DiGraph()
        pos = {}  # Position mapping
        x_offset = 0  # Horizontal offset for each path
        longest_path = max(paths, key=len)  # Identify the longest path

        # Setting up positions
        for path in paths:
            for i, node in enumerate(path):
                pos[node] = (x_offset, -i)  # Assign position
            x_offset += 1  # Increment x offset for each path

        # Adding paths to the graph
        for path in paths:
            nx.add_path(G, path)

        # Drawing
        plt.figure(figsize=(8, 5))
        node_colors = ["red" if node in longest_path else "skyblue" for node in G.nodes()]
        edge_colors = ["red" if (u, v) in zip(longest_path, longest_path[1:]) else "black" for u, v in G.edges()]

        nx.draw(G, pos, with_labels=True, arrows=True, node_size=700, node_color=node_colors, 
                edge_color=edge_colors, font_size=10, font_weight="bold", arrowstyle="->", arrowsize=20)
        plt.show()
    
    #show results
    print("\n")
    print("Bar graph below shows number of variants matched (>0) for each haplogroup:")
    plt.bar(height=scores["match"].values, x=scores.index)
    plt.title("Count matched variants")
    plt.xticks(rotation=90, fontsize=5.5)
    plt.show()
    
    print("\n")
    print("Bar graph below shows percentage of variants matched (>0) for each haplogroup:")
    plt.bar(height=scores["percent"].values, x=scores.index)
    plt.title("Percentage(%) of variants matched")
    plt.xticks(rotation=90, fontsize=5.5)
    plt.show()
    print("percentage = matched_variants/variants_defining_haplogroup")
    
    print("\n")
    print("Bar graph below shows score1 (description below) of variants matched (>0) for each haplogroup:")
    plt.bar(height=scores["log_score"].values, x=scores.index)
    plt.title("Score1 (measure of fit to haplogroups)")
    plt.xticks(rotation=90, fontsize=5.5)
    plt.show()
    print("score1 = percentage * log(count + 1)")
    print("score1 aims to balance count and percentage of variants matched per haplogroup")
    
    print("\n")
    print("Bar graph below shows score2 (description below) of variants matched (>0) for each haplogroup:")
    plt.bar(height=scores["harmonic_score"].values, x=scores.index)
    plt.title("Score2 (measure of fit to haplogroups)")
    plt.xticks(rotation=90, fontsize=5.5)
    plt.show()
    print("score2 = percentage * (2 / (1/count + percentage))")
    print("score2 aims to balance count and percentage of variants matched per haplogroup")
    
    print("Below arrow diagram shows the relatioship between matched haplogroups:")
    visualize_paths_nx_vertical_with_longest_path_color(longest_paths)
    
    print("\n")
    print("According to the arrow diagrams, you most likely belong to the red path")

    longest = []
    for path in longest_paths:
        if len(path)>len(longest):
            longest=path
    haplo = longest[-1]
    print("\n")
    print("you most likely belog to same haplogroup with these samples")
    print(f"https://www.yfull.com/tree/{haplo}")
    
    return (matched, scores, filtered_tree)

