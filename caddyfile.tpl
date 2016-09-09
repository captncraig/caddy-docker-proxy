{{ $CurrentContainer := where $ "ID" .Docker.CurrentContainerID | first }}

{{ define "upstream" }}
	{{ if .Address }}
		{{/* If we got the containers from swarm and this container's port is published to host, use host IP:PORT */}}
		{{ if and .Container.Node.ID .Address.HostPort }}
    # {{ .Container.Node.Name }}/{{ .Container.Name }}
    upstream {{ .Container.Node.Address.IP }}:{{ .Address.HostPort }}
		{{/* If there is no swarm node or the port is not published on host, use container's IP:PORT */}}
		{{ else if .Network }}
    # {{ .Container.Name }}
    upstream {{ .Network.IP }}:{{ .Address.Port }}
		{{ end }}
	{{ else if .Network }}
    # {{ .Container.Name }}
    upstream {{ .Network.IP }}
	{{ end }}
{{ end }}

{{ range $host, $containers := groupByMulti $ "Env.VIRTUAL_HOST" "," }}
{{ $host }} {
    proxy / {
    {{ range $container := $containers }}
        {{ $addrLen := len $container.Addresses }}
        {{ range $knownNetwork := $CurrentContainer.Networks }}
            {{ range $containerNetwork := $container.Networks }}
                {{ if eq $knownNetwork.Name $containerNetwork.Name }}

        # can connect with "{{ $containerNetwork.Name }}" network

                    {{ if eq $addrLen 1 }}
					    {{ $address := index $container.Addresses 0 }}
		{{ template "upstream" (dict "Container" $container "Address" $address "Network" $containerNetwork) }}
				    {{ else }}
                        {{/* If more than one port exposed, use the one matching VIRTUAL_PORT env var, falling back to standard web port 80 */}}
					    {{ $port := coalesce $container.Env.VIRTUAL_PORT "80" }}
					    {{ $address := where $container.Addresses "Port" $port | first }}
		{{ template "upstream" (dict "Container" $container "Address" $address "Network" $containerNetwork) }}
				    {{ end }}
                {{end}}
            {{end}}
        {{end}}
    {{end}}
    }
}

{{end}}