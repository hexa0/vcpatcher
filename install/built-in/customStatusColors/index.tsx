import definePlugin from "@utils/types";

export default definePlugin({
    name: "StatusColorThemer",
    description: "Allows you to theme status colors",
    authors: [{ name: "hexa0", id: 573643611317600256n }],

    getThemedStatusColor(status: string) {
        const varMap: Record<string, string> = {
            online: "--custom-status-online",
            idle: "--custom-status-idle",
            dnd: "--custom-status-dnd",
            streaming: "--custom-status-streaming",
            offline: "--custom-status-offline"
        };

        const varName = varMap[status] || varMap.offline;
        return getComputedStyle(document.documentElement).getPropertyValue(varName).trim() || "#82838b";
    },

    useStatusFillColor(status: string) {
        return {
            resolve: () => ({
                hex: () => (this.getThemedStatusColor(status) || "#82838b")
            })
        };
    },

    patches: [
        {
            find: "unsafe_rawColors.GREEN_NEW_38",
            replacement: {
                match: /function \w+\(e\)\{switch\(e\)\{case \i\.\i\.ONLINE:.*?default:return \i\.\i\.unsafe_rawColors\.NEUTRAL_34\}\}/,
                replace: `function b(e){return $self.useStatusFillColor(e)}`
            }
        }
    ]
});
