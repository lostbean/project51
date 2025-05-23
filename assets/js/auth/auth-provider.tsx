import { Auth0Provider } from "@auth0/auth0-react";
import React from "react";

import {
  APP_AUTH0_DOMAIN,
  APP_AUTH0_CLIENT_ID,
  APP_AUTH0_CALLBACK_URL,
  APP_AUTH0_AUDIENCE,
} from "env";

export const Auth0Provider51 = ({ children }) => {
  // In Auth0 configure it under Settings > Applications
  // Use it in SPA mode
  const domain = APP_AUTH0_DOMAIN;
  const clientId = APP_AUTH0_CLIENT_ID;
  // Attention: use dev mode use `localhost` instead of `0.0.0.0` to avoid secure origin issues
  const redirectUri = APP_AUTH0_CALLBACK_URL;
  // In Auth0 configure it under Settings > APIs
  const audience = APP_AUTH0_AUDIENCE;

  const scopes = ["read:current_user", "update:current_user_metadata"];

  if (!(domain && clientId && redirectUri)) {
    return null;
  }

  return (
    <Auth0Provider
      domain={domain}
      clientId={clientId}
      authorizationParams={{
        audience: audience,
        redirect_uri: window.location.origin,
        scope: scopes.join(" "),
      }}
    >
      {children}
    </Auth0Provider>
  );
};
