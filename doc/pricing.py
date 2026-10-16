from casegen import EXPECT, generate

sets = {
    "subtotal": [25, 75, 200],
    "discount": ["0%", "10%", "20%"],
    "promo": ["none", "apr", "fall"],
    "total": [EXPECT],
}

rules = {
    "exclude": [
        {
            "criteria": "subtotal < 100 and discount == '20%'",
            "description": "Total must be above $100 to apply the 20% discount",
        },
        {
            "criteria": "(subtotal < 50) and discount == '10%'",
            "note": "Total must be above $50 to apply the 10% discount",
        },
        {
            "criteria": "discount != '20%' and subtotal == 200",
            "reason": "Orders over 100 automatically get 20% discount",
        },
        {
            "criteria": "discount != '10%' and subtotal == 75",
            "reason": "Orders between 50 and 100 automatically get 10% discount",
        },
        {
            "criteria": "discount == '20%' and promo != 'none'",
            "reason": "20% discount cannot be combined with promo",
        },
    ],
    "expect": [
        {"subtotal": 25, "promo": "none", "total": "25.00"},
        {
            "subtotal": 25,
            "promo": "apr",
            "total": "17.50",
            "reason": "apr promo is 30%",
        },
        {
            "subtotal": 25,
            "promo": "fall",
            "total": "16.25",
            "note": "fall promo is 35%",
        },
        {"subtotal": 75, "promo": "none", "total": "67.50", "note": "10% discount"},
        {
            "subtotal": 75,
            "promo": "apr",
            "total": "47.25",
            "reason": "10% + apr promo is 30%",
        },
        {
            "subtotal": 75,
            "promo": "fall",
            "total": "43.88",
            "note": "10% + fall promo is 35%",
        },
        {"subtotal": 200, "promo": "none", "total": "160.00", "note": "20% discount"},
    ],
}

if __name__ == "__main__":
    print(generate(sets, rules, "exclude_as_text"), end="")
