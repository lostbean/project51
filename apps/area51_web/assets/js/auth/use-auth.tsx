import { useAuth0 } from "@auth0/auth0-react";

import { APP_AUTH0_AUDIENCE } from "env";

const scopes = ["read:current_user", "update:current_user_metadata"];

export const useAuth = () => {
  const {
    isAuthenticated,
    isLoading,
    loginWithRedirect,
    logout,
    user,
    getAccessTokenSilently,
  } = useAuth0();

  const getToken = async () => {
    if (isAuthenticated) {
      try {
        const token = await getAccessTokenSilently({
          authorizationParams: {
            audience: APP_AUTH0_AUDIENCE,
            scope: scopes.join(" "),
          },
        });
        return token;
      } catch (error) {
        return null;
      }
    }
  };

  // Call Auth0 logout
  const handleLogout = () => {
    console.info("logging out 👋");
    logout({ logoutParams: { returnTo: window.location.origin } });
  };

  return {
    isAuthenticated,
    isLoading,
    login: loginWithRedirect,
    logout: handleLogout,
    user,
    getToken,
  };
};
