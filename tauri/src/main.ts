import { mount } from 'svelte';
import App from './App.svelte';
import { applyTokens } from './lib/design/theme';
import './lib/design/theme.css';

applyTokens();

export default mount(App, { target: document.getElementById('app')! });
