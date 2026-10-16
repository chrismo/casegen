from casegen import generate

sets = {
    "payment": ["Credit", "Check", "Online Bank"],
    "amount": [100, 1_000, 10_000],
    "shipping": ["Ground", "Air"],
    "ship_to_country": ["US", "Outside US"],
    "bill_to_country": ["US", "Outside US"],
}

rules = {
    "exclude": [
        {
            "criteria": 'shipping == "Ground" and ship_to_country == "Outside US"',
            "description": "Our ground shipper will only ship things within the US",
        },
        {
            "criteria": lambda c: c.payment == "Check"
            and c.bill_to_country == "Outside US",
            "description": "Our bank will not accept checks written from banks outside the US.",
        },
        {
            "criteria": lambda c: c.payment == "Online Bank" and c.amount >= 1_000,
            "description": (
                "While the online bank will process amounts > $1,000, we've experienced\n"
                "occasional problems with their services and have had to write off some\n"
                "transactions, so we no longer allow this payment option for amounts\n"
                "greater than $1,000.\n"
            ),
        },
        {
            "criteria": lambda c: c.ship_to_country == "US"
            and c.bill_to_country == "Outside US",
            "description": "If we're shipping to the US, billing party cannot be outside US",
        },
    ]
}

if __name__ == "__main__":
    print(generate(sets, rules, "exclude_as_text"), end="")
