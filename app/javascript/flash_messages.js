document.addEventListener('turbo:load', () => {
    document.querySelectorAll('.flash .close-button').forEach(button => {
        button.addEventListener('click', (event) => {
            event.target.parentElement.style.display = 'none';
        });
    });
});
