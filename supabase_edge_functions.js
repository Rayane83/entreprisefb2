// ===================================
// EDGE FUNCTIONS SUPABASE
// ===================================

/**
 * Fonction Edge : get-discord-roles
 * 
 * Cette fonction doit être déployée dans Supabase Edge Functions
 * Commande : supabase functions deploy get-discord-roles
 */

// Fichier : supabase/functions/get-discord-roles/index.ts
const getDiscordRolesFunction = `
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RequestData {
  guildId: string
  discordUserId: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { guildId, discordUserId }: RequestData = await req.json()
    
    if (!guildId || !discordUserId) {
      return new Response(
        JSON.stringify({ error: 'Missing guildId or discordUserId' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Configuration Discord Bot (à configurer dans Supabase Secrets)
    const DISCORD_BOT_TOKEN = Deno.env.get('DISCORD_BOT_TOKEN')
    if (!DISCORD_BOT_TOKEN) {
      throw new Error('DISCORD_BOT_TOKEN not configured')
    }

    // Récupérer les informations du membre Discord
    const memberResponse = await fetch(
      \`https://discord.com/api/v10/guilds/\${guildId}/members/\${discordUserId}\`,
      {
        headers: {
          'Authorization': \`Bot \${DISCORD_BOT_TOKEN}\`,
          'Content-Type': 'application/json'
        }
      }
    )

    if (!memberResponse.ok) {
      throw new Error(\`Discord API error: \${memberResponse.status}\`)
    }

    const memberData = await memberResponse.json()
    const userRoles = memberData.roles || []

    // Récupérer les informations des rôles du serveur
    const rolesResponse = await fetch(
      \`https://discord.com/api/v10/guilds/\${guildId}/roles\`,
      {
        headers: {
          'Authorization': \`Bot \${DISCORD_BOT_TOKEN}\`,
          'Content-Type': 'application/json'
        }
      }
    )

    const allRoles = await rolesResponse.json()
    
    // Filtrer les rôles de l'utilisateur
    const memberRoleDetails = allRoles.filter(role => 
      userRoles.includes(role.id)
    ).map(role => ({
      id: role.id,
      name: role.name,
      color: role.color,
      position: role.position
    }))

    // Initialiser Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Récupérer les informations de l'entreprise
    const { data: enterprise, error: enterpriseError } = await supabase
      .from('enterprises')
      .select('*')
      .eq('guild_id', guildId)
      .single()

    if (enterpriseError && enterpriseError.code !== 'PGRST116') {
      console.error('Error fetching enterprise:', enterpriseError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        roles: memberRoleDetails,
        enterpriseId: enterprise?.id || null,
        enterpriseName: enterprise?.name || 'Unknown',
        discordUser: {
          id: memberData.user?.id,
          username: memberData.user?.username,
          discriminator: memberData.user?.discriminator,
          avatar: memberData.user?.avatar
        }
      }),
      { 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error in get-discord-roles function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message,
        success: false 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
`

/**
 * Fonction Edge : sync-user-roles  
 * 
 * Synchronise automatiquement les rôles Discord lors de la connexion
 */

const syncUserRolesFunction = `
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { userId, guildId } = await req.json()
    
    // Initialiser Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Récupérer les informations utilisateur de la table auth
    const { data: user, error: userError } = await supabase.auth.admin.getUserById(userId)
    
    if (userError || !user) {
      throw new Error('User not found')
    }

    const userMetadata = user.user?.user_metadata || {}
    const discordUserId = userMetadata.provider_id || userMetadata.sub

    if (!discordUserId) {
      throw new Error('Discord user ID not found in metadata')
    }

    // Appeler la fonction get-discord-roles
    const { data: rolesData, error: rolesError } = await supabase.functions.invoke('get-discord-roles', {
      body: { guildId, discordUserId }
    })

    if (rolesError) {
      throw new Error(\`Failed to get Discord roles: \${rolesError.message}\`)
    }

    // Déterminer le rôle principal
    const roles = rolesData.roles || []
    const roleHierarchy = ['staff', 'patron', 'co-patron', 'dot', 'employe']
    
    let primaryRole = 'employe'
    for (const roleName of roleHierarchy) {
      if (roles.some(r => r.name.toLowerCase().includes(roleName))) {
        primaryRole = roleName
        break
      }
    }

    // Mettre à jour le profil utilisateur
    const { error: profileError } = await supabase
      .from('user_profiles')
      .upsert({
        id: userId,
        discord_id: discordUserId,
        discord_username: userMetadata.full_name || userMetadata.name || 'Unknown',
        current_role: primaryRole,
        enterprise_id: rolesData.enterpriseId,
        updated_at: new Date().toISOString()
      })

    if (profileError) {
      throw new Error(\`Failed to update user profile: \${profileError.message}\`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        userRole: primaryRole,
        enterprise: rolesData.enterpriseName,
        roles: roles
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in sync-user-roles function:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message,
        success: false 
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
`

// ===================================
// INSTRUCTIONS DE DÉPLOIEMENT
// ===================================

const deploymentInstructions = `
# DÉPLOIEMENT DES EDGE FUNCTIONS

## Prérequis
1. Installer Supabase CLI : npm install -g supabase
2. Se connecter : supabase login
3. Lier le projet : supabase link --project-ref dutvmjnhnrpqoztftzgd

## Structure des fichiers
supabase/
  functions/
    get-discord-roles/
      index.ts
    sync-user-roles/
      index.ts

## Déploiement
1. supabase functions deploy get-discord-roles
2. supabase functions deploy sync-user-roles

## Configuration des secrets
supabase secrets set DISCORD_BOT_TOKEN=your_bot_token_here

## Test des fonctions
supabase functions invoke get-discord-roles --data '{"guildId":"1404608015230832742","discordUserId":"123456789"}'
`

module.exports = {
  getDiscordRolesFunction,
  syncUserRolesFunction,
  deploymentInstructions
};