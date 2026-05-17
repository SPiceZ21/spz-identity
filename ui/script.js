let selectedGender = 0; // 0 = Male, 1 = Female

document.addEventListener('DOMContentLoaded', () => {
    const app = document.getElementById('app');
    const usernameInput = document.getElementById('username');
    const errorMsg = document.getElementById('error-username');
    const genderCards = document.querySelectorAll('.gender-card');
    const submitBtn = document.getElementById('submit-btn');

    // Handle NUI Messages
    window.addEventListener('message', (event) => {
        const data = event.data;
        if (data.type === 'showCharacterCreation') {
            if (data.suggestedName) {
                usernameInput.value = data.suggestedName;
            } else {
                usernameInput.value = '';
            }
            errorMsg.textContent = '';
            app.classList.remove('hidden');
            usernameInput.focus();
        } else if (data.type === 'hideCharacterCreation') {
            app.classList.add('hidden');
        } else if (data.type === 'characterCreationError') {
            errorMsg.textContent = data.message;
            submitBtn.disabled = false;
            submitBtn.querySelector('.btn-text').textContent = 'INITIALIZE IDENTITY';
        }
    });

    // Gender Selection
    genderCards.forEach(card => {
        card.addEventListener('click', () => {
            genderCards.forEach(c => c.classList.remove('active'));
            card.classList.add('active');
            selectedGender = parseInt(card.getAttribute('data-gender'), 10);
        });
    });

    // Submit form
    submitBtn.addEventListener('click', () => {
        const username = usernameInput.value.trim();
        
        if (username.length < 3 || username.length > 20) {
            errorMsg.textContent = 'Username must be 3-20 characters';
            return;
        }

        if (!/^[a-zA-Z0-9_]+$/.test(username)) {
            errorMsg.textContent = 'Letters, numbers, and underscores only';
            return;
        }

        errorMsg.textContent = '';
        submitBtn.disabled = true;
        submitBtn.querySelector('.btn-text').textContent = 'PROCESSING...';

        fetch(`https://${GetParentResourceName()}/submitCharacterCreation`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body: JSON.stringify({
                username: username,
                gender: selectedGender
            })
        }).catch(err => {
            console.error('Failed to submit character creation:', err);
            submitBtn.disabled = false;
            submitBtn.querySelector('.btn-text').textContent = 'INITIALIZE IDENTITY';
        });
    });

    // Handle Escape Key (Optional: maybe not allowed since they must create)
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !app.classList.contains('hidden')) {
            submitBtn.click();
        }
    });
});
