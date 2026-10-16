from casegen import EXPECT, generate

sets = {
    "width": ["inside", "outside"],
    "height": ["inside", "outside"],
    "aspect": ["wide", "tall"],
    "result": [EXPECT],
}

rules = {
    "exclude": [
        {
            "width": "inside",
            "height": "outside",
            "aspect": "wide",
            "note": "a narrower image cannot have a wide aspect",
        },
        {
            "width": "outside",
            "height": "inside",
            "aspect": "tall",
            "note": "a shorter image cannot have a tall aspect",
        },
    ],
    "expect": [
        {"width": "inside", "height": "inside", "aspect": "wide", "result": "200x100"},
        {"width": "inside", "height": "inside", "aspect": "tall", "result": "100x200"},
        {"width": "inside", "height": "outside", "aspect": "tall", "result": "100x400"},
        {"width": "outside", "height": "inside", "aspect": "wide", "result": "400x100"},
        {
            "width": "outside",
            "height": "outside",
            "aspect": "wide",
            "result": "500x400",
        },
        {
            "width": "outside",
            "height": "outside",
            "aspect": "tall",
            "result": "400x500",
        },
    ],
}

if __name__ == "__main__":
    print(generate(sets, rules, "exclude_as_table"), end="")
