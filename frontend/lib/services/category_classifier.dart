class CategoryClassifier {
  static const Map<String, List<String>> _keywords = {
    "Groceries": [
      "grocery", "groceries", "supermarket", "bigbasket", "blinkit", "zepto",
      "dmart", "reliance fresh", "vegetable", "vegetables", "veggie", "fruit",
      "fruits", "potatoes", "potato", "tomatoes", "tomato", "onion", "onions",
      "milk", "bread", "butter", "cheese", "paneer", "rice", "dal", "flour",
      "atta", "sugar", "salt", "oil", "kirana", "spices", "produce",
      "eggs", "chicken", "fish", "meat", "dairy", "groceris", "grocrey",
      "groceri", "suprmarket", "bigbaskt"
    ],
    "Food": [
      "restaurant", "cafe", "food", "dining", "pizza", "burger", "swiggy",
      "zomato", "dominos", "kfc", "mcdonald", "biryani", "meal", "kitchen",
      "dhaba", "hotel", "canteen", "bakery", "snack", "tiffin", "mess",
      "lunch", "dinner", "breakfast", "eat", "paring", "foog", "foof",
      "restraunt", "resturant", "resturante", "swigy", "zomatoo"
    ],
    "Juice": [
      "juice", "smoothie", "beverage", "coffee", "tea", "chai", "starbucks",
      "cafe coffee", "ccd", "barista", "cold drink", "soda", "milkshake",
      "starbuck", "coldrink", "milkshak"
    ],
    "Shopping": [
      "mall", "shop", "amazon", "flipkart", "myntra", "fashion", "clothing",
      "apparel", "retail", "bazaar", "zara", "h&m", "shirt", "shirts",
      "pants", "shoes", "jewellery", "bags", "wallets", "dress", "jeans",
      "t-shirt", "tshirt", "garment", "outfit", "boutique", "wardrobe",
      "accessories", "footwear", "sneakers", "cloth", "shoping", "shoppin",
      "amazn", "flipkartt", "myntraa"
    ],
    "Health": [
      "hospital", "clinic", "doctor", "health", "lab", "diagnostic",
      "apollo", "fortis", "medplus", "pharmeasy", "1mg", "checkup",
      "hospitall", "doctorr", "clinicc"
    ],
    "Medicine": [
      "pharmacy", "medicine", "medical", "drug", "chemist", "tablet",
      "capsule", "prescription", "medico", "ayurvedic", "medicin",
      "medicale", "chemistt"
    ],
    "Fuel": [
      "petrol", "diesel", "fuel", "gas station", "hp", "iocl", "bpcl",
      "indian oil", "bharat petroleum", "shell", "cng", "lpg", "fuul",
      "fual"
    ],
    "Recharge": [
      "recharge", "prepaid", "postpaid", "airtel", "jio", "vi", "vodafone",
      "mobile", "sim", "data pack", "recharg", "rechar", "prepaidd", "postpaidd"
    ],
    "Electricity": [
      "electricity", "power", "eb bill", "bescom", "tneb", "mseb", "kseb",
      "electric", "energy bill", "electrity", "powerbill"
    ],
    "Transport": [
      "uber", "ola", "rapido", "metro", "bus", "train", "railway", "taxi",
      "cab", "auto", "transport", "irctc", "toll", "rickshaw", "transprt",
      "uberr", "olaa", "rapidoo"
    ],
    "Entertainment": [
      "movie", "cinema", "netflix", "spotify", "hotstar", "prime", "game",
      "theatre", "concert", "event", "ticket", "pvr", "inox", "gaming",
    ],
    "Gadgets": [
      "electronics", "mobile", "laptop", "computer", "gadget", "croma",
      "reliance digital", "samsung", "apple", "iphone", "accessory",
    ],
    "Bills": [
      "subscription", "utility", "water", "gas bill", "internet",
      "broadband", "wifi", "act fibernet", "billz", "bils", "utilityy"
    ],
    "Rent": [
      "rent", "lease", "housing", "apartment", "flat", "landlord",
    ],
    "Travel": [
      "flight", "airline", "hotel", "booking", "makemytrip", "goibibo",
      "travel", "trip", "vacation", "airbnb",
    ],
    "Insurance": [
      "insurance", "lic", "policy", "premium", "health insurance",
      "life insurance",
    ],
    "Gift": [
      "gift", "present", "donation", "charity",
    ],
    "Business": [
      "business", "office", "corporate", "professional", "consulting",
    ],
  };

  static String classify(String text) {
    final lower = text.toLowerCase();
    int bestScore = 0;
    String bestCategory = "Others";

    // Prefer categories that have more specific/longer keyword matches
    _keywords.forEach((category, words) {
      int score = 0;
      for (final word in words) {
        if (RegExp(r'\b' + RegExp.escape(word) + r'\b').hasMatch(lower)) {
          // Longer keywords are more specific - give higher weight
          score += word.length > 5 ? 2 : 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    return bestCategory;
  }

  static String classifyMerchant(String merchantName) {
    return classify(merchantName);
  }
}
