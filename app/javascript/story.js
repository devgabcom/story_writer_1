document.addEventListener('turbo:load', () => {
    const addKeyElementButton = document.getElementById('add-key-element');
    const keyElementsContainer = document.getElementById('key-elements-container');
    let keyElementCount = document.querySelectorAll('.key-element').length;

    function addKeyElement() {
        if (keyElementCount < 5) {
            const keyElementDiv = document.createElement('div');
            keyElementDiv.className = 'key-element';

            const inputField = document.createElement('input');
            inputField.type = 'text';
            inputField.name = 'story[key_elements][]';
            inputField.size = 30;

            const removeButton = document.createElement('button');
            removeButton.type = 'button';
            removeButton.className = 'remove-key-element';
            removeButton.textContent = 'Remove';
            removeButton.addEventListener('click', () => {
                keyElementDiv.remove();
                keyElementCount--;
                if (keyElementCount < 5) {
                    addKeyElementButton.style.display = 'inline';
                }
            });

            keyElementDiv.appendChild(inputField);
            keyElementDiv.appendChild(removeButton);
            keyElementsContainer.appendChild(keyElementDiv);

            keyElementCount++;
            if (keyElementCount >= 5) {
                addKeyElementButton.style.display = 'none';
            }
        }
    }

    if (addKeyElementButton) {
        addKeyElementButton.addEventListener('click', addKeyElement);
    }

    // Use event delegation to attach event listeners to dynamically added content
    document.addEventListener('click', (event) => {
        if (event.target.classList.contains('remove-key-element')) {
            event.target.parentElement.remove();
            keyElementCount--;
            if (keyElementCount < 5) {
                addKeyElementButton.style.display = 'inline';
            }
        } else if (event.target.classList.contains('toggle-detail')) {
            const targetId = event.target.getAttribute('data-target');
            const targetElement = document.getElementById(targetId);
            if (targetElement.style.display === 'none') {
                targetElement.style.display = 'block';
                event.target.textContent = 'Hide Details';
            } else {
                targetElement.style.display = 'none';
                event.target.textContent = 'Show Details';
            }
        }
    });
});