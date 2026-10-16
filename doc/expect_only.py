from casegen import EXPECT, generate

sets = {
    "duration": [12, 24, 36, 60],
    "unit": [60, 3600],
    "result": [EXPECT],
}

rules = {
    "expect": [
        {"duration": 12, "unit": 60, "result": "12m"},
        {"duration": 12, "unit": 3600, "result": "12h"},
        {"duration": 24, "unit": 60, "result": "24m"},
        {"duration": 24, "unit": 3600, "result": "1d"},
        {"duration": 36, "unit": 60, "result": "36m"},
        {"duration": 36, "unit": 3600, "result": "1d 12h"},
        {"duration": 60, "unit": 60, "result": "1h"},
        {"duration": 60, "unit": 3600, "result": "2d 12h"},
    ],
}

if __name__ == "__main__":
    print(generate(sets, rules, "exclude_inline"), end="")
