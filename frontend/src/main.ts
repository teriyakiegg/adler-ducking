import { createApp } from 'vue'
import { createPinia } from 'pinia'
import vue3GoogleLogin from 'vue3-google-login'

import App from './App.vue'
import router from './router'
import './assets/main.css'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(vue3GoogleLogin, {
  clientId: '1081307309475-742n1t9n53bpd1gb14cuc5vu7hda72g0.apps.googleusercontent.com',
})

app.mount('#app')
