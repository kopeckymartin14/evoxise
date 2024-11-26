import { LightningElement } from 'lwc';

export default class FaqComponent extends LightningElement {
    activeTile = null;

    handleClick(event) {
        const clickedTile = event.currentTarget;
        const info = clickedTile.nextElementSibling;

        if (this.activeTile && this.activeTile !== clickedTile) {
            // Collapse the currently active tile
            this.activeTile.classList.remove('active');
            this.activeTile.nextElementSibling.style.maxHeight = 0;
        }

        // Toggle the clicked tile
        clickedTile.classList.toggle('active');

        if (clickedTile.classList.contains('active')) {
            // Expand the clicked tile
            info.style.maxHeight = info.scrollHeight + 'px';
            this.activeTile = clickedTile; // Update active tile
        } else {
            // Collapse the clicked tile
            info.style.maxHeight = 0;
            this.activeTile = null; // Clear active tile
        }
    }
}