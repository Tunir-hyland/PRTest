// DEMO FILE: Intentionally Bad Code for Testing PR Review Agent
// This file contains various code issues that should be detected by the agent

// BUG 1: Hardcoded API key (CRITICAL)
const API_KEY = "sk-1234567890abcdef";
const password = "admin123";

// BUG 2: console.log debugging (INFO)
function processUser(user) {
    console.log("Processing user:", user);
    
    // BUG 3: var usage instead of let/const (INFO)
    var userName = user.name;
    
    // BUG 4: == instead of === (WARNING)
    if (user.age == null) {
        return null;
    }
    
    // BUG 5: Empty catch block (WARNING)
    try {
        doSomething(user);
    } catch (e) {
        // Empty catch - swallows errors
    }
    
    return userName;
}

// BUG 6: debugger statement (WARNING)
function calculateTotal(items) {
    debugger;
    let total = 0;
    
    // BUG 7: Old-style loop (SUGGESTION)
    for (var i = 0; i < items.length; i++) {
        total += items[i].price;
    }
    
    return total;
}

// LARGE METHOD: This function is intentionally long (over 50 lines)
function complexBusinessLogic(data) {
    // TODO: Refactor this huge function
    let result = [];
    
    // Complex nested logic
    if (data && data.items) {
        for (let i = 0; i < data.items.length; i++) {
            let item = data.items[i];
            
            if (item.active) {
                if (item.category === 'electronics') {
                    if (item.price > 100) {
                        result.push({
                            id: item.id,
                            name: item.name,
                            discounted: item.price * 0.9
                        });
                    } else if (item.price > 50) {
                        result.push({
                            id: item.id,
                            name: item.name,
                            discounted: item.price * 0.95
                        });
                    } else {
                        result.push(item);
                    }
                } else if (item.category === 'clothing') {
                    if (item.season === 'winter') {
                        result.push({
                            id: item.id,
                            name: item.name,
                            discounted: item.price * 0.7
                        });
                    } else {
                        result.push({
                            id: item.id,
                            name: item.name,
                            discounted: item.price * 0.85
                        });
                    }
                } else {
                    result.push(item);
                }
            }
        }
    }
    
    // More processing
    result.forEach(item => {
        if (item.discounted) {
            console.log(`Discounted: ${item.name}`);
        }
    });
    
    // FIXME: This sorting is inefficient
    result.sort((a, b) => {
        if (a.price && b.price) {
            return b.price - a.price;
        }
        return 0;
    });
    
    return result;
}

// BUG 8: Assignment in if condition (CRITICAL)
function checkStatus(user) {
    if (status = user.status) {  // Should be === not =
        return status;
    }
    return 'unknown';
}

// BUG 9: Unnecessary return await (INFO)
async function fetchUserData(id) {
    return await fetch(`/api/users/${id}`);
}

// DUPLICATE CODE BLOCK (should be detected)
function validateEmail(email) {
    if (!email) return false;
    if (email.length < 5) return false;
    if (!email.includes('@')) return false;
    if (!email.includes('.')) return false;
    return true;
}

// DUPLICATE CODE BLOCK (same logic repeated)
function validateUsername(username) {
    if (!username) return false;
    if (username.length < 5) return false;
    if (!username.includes('@')) return false;
    if (!username.includes('.')) return false;
    return true;
}

// BUG 10: Complex condition (SUGGESTION for improvement)
function isEligibleForDiscount(user) {
    if (user.age > 18 && user.membership && user.points > 100 && user.verified && !user.banned) {
        return true;
    }
    return false;
}

// TODO: Implement proper error handling
// HACK: Quick fix for production bug
// XXX: This is a temporary workaround
function quickFix(data) {
    // NOTE: Remove this before release
    return data || {};
}

// BUG 11: Promise chain instead of async/await (SUGGESTION)
function loadData() {
    return fetch('/api/data')
        .then(res => res.json())
        .then(data => processData(data))
        .then(processed => saveData(processed))
        .then(saved => console.log('Done'));
}

// Export for testing
module.exports = {
    processUser,
    calculateTotal,
    complexBusinessLogic,
    checkStatus,
    fetchUserData,
    validateEmail,
    validateUsername,
    isEligibleForDiscount,
    quickFix,
    loadData
};
