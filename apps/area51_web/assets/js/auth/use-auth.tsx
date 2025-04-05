import { useAuth0 } from "@auth0/auth0-react";

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
    try {
      if (isAuthenticated) {
        return await getAccessTokenSilently();
      }
      return null;
    } catch (error) {
      console.error("Error getting token:", error);
      return null;
    }
  };

  return {
    isAuthenticated,
    isLoading,
    login: loginWithRedirect,
    logout: () =>
      logout({ logoutParams: { returnTo: window.location.origin } }),
    user,
    getToken,
  };
};
