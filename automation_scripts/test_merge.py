import difflib

def merge_similar_subjects(subjects_dict):
    merged = {}
    keys = sorted(subjects_dict.keys(), key=len, reverse=True)
    for key in keys:
        found_merge = False
        for m_key in list(merged.keys()):
            ratio = difflib.SequenceMatcher(None, key.lower(), m_key.lower()).ratio()
            # is_substring only needs to check key in m_key because key is shorter or equal to m_key
            is_substring = (key.lower() in m_key.lower()) and min(len(key), len(m_key)) >= 5
            
            if ratio > 0.85 or is_substring:
                merged[m_key].extend(subjects_dict[key])
                merged[m_key] = list(set(merged[m_key]))
                found_merge = True
                break
        if not found_merge:
            merged[key] = list(set(subjects_dict[key]))
    return merged

test_dict = {
    "E Commerce And Erp": [1],
    "E Commerce": [2],
    "Operating Systems": [1],
    "Operating System": [2],
    "Cryptography And Network Security": [1],
    "Network Security": [2]
}

m = merge_similar_subjects(test_dict)
for k, v in m.items():
    print(k, v)
